# Accessibility Testing for CFWheels Applications

## Description
Comprehensive accessibility testing patterns to ensure CFWheels applications meet WCAG 2.1 AA standards and provide excellent user experiences for all users, including those with disabilities.

## Key Points
- WCAG 2.1 AA compliance is the minimum standard
- Automated testing catches 30-40% of accessibility issues
- Manual testing and user testing are essential
- Accessibility should be tested throughout development, not just at the end

## WCAG 2.1 AA Testing Requirements

### 1. Perceivable Content Testing

#### Color Contrast Testing
```javascript
// Automated color contrast testing
async function testColorContrast(page) {
    const contrastResults = await page.evaluate(() => {
        const elements = document.querySelectorAll('*');
        const failures = [];

        function getLuminance(r, g, b) {
            const [rs, gs, bs] = [r, g, b].map(c => {
                c = c / 255;
                return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
            });
            return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs;
        }

        function getContrastRatio(color1, color2) {
            const lum1 = getLuminance(...color1);
            const lum2 = getLuminance(...color2);
            const brightest = Math.max(lum1, lum2);
            const darkest = Math.min(lum1, lum2);
            return (brightest + 0.05) / (darkest + 0.05);
        }

        function parseColor(colorStr) {
            if (colorStr.startsWith('rgb')) {
                const matches = colorStr.match(/\\d+/g);
                return matches ? matches.map(Number) : [0, 0, 0];
            }
            return [0, 0, 0]; // Default fallback
        }

        elements.forEach(element => {
            const styles = window.getComputedStyle(element);
            const bgColor = parseColor(styles.backgroundColor);
            const textColor = parseColor(styles.color);
            const fontSize = parseFloat(styles.fontSize);

            if (element.textContent && element.textContent.trim()) {
                const contrast = getContrastRatio(bgColor, textColor);
                const requiredRatio = fontSize >= 18 ? 3.0 : 4.5; // WCAG AA standards

                if (contrast < requiredRatio) {
                    failures.push({
                        element: element.tagName + (element.className ? '.' + element.className.split(' ')[0] : ''),
                        contrast: contrast.toFixed(2),
                        required: requiredRatio,
                        fontSize: fontSize,
                        textContent: element.textContent.substring(0, 50)
                    });
                }
            }
        });

        return failures;
    });

    return contrastResults;
}

// Usage in wheels_execute
const contrastFailures = await testColorContrast(page);
expect(contrastFailures.length).toBe(0,
    `Color contrast failures found: ${JSON.stringify(contrastFailures, null, 2)}`
);
```

#### Alternative Text Testing
```javascript
async function testImageAccessibility(page) {
    const imageResults = await page.evaluate(() => {
        const images = document.querySelectorAll('img');
        const failures = [];

        images.forEach((img, index) => {
            const alt = img.getAttribute('alt');
            const src = img.src;

            // Check for missing alt attributes
            if (alt === null) {
                failures.push({
                    type: 'missing_alt',
                    element: `img[${index}]`,
                    src: src,
                    issue: 'Image missing alt attribute'
                });
            }
            // Check for placeholder alt text
            else if (alt === 'image' || alt === 'photo' || alt === src) {
                failures.push({
                    type: 'placeholder_alt',
                    element: `img[${index}]`,
                    src: src,
                    alt: alt,
                    issue: 'Image has placeholder alt text'
                });
            }
            // Decorative images should have empty alt
            else if (img.closest('[role="presentation"]') && alt !== '') {
                failures.push({
                    type: 'decorative_alt',
                    element: `img[${index}]`,
                    src: src,
                    alt: alt,
                    issue: 'Decorative image should have empty alt attribute'
                });
            }
        });

        return failures;
    });

    return imageResults;
}
```

### 2. Operable Interface Testing

#### Keyboard Navigation Testing
```javascript
async function testKeyboardNavigation(page) {
    const navigationResults = {
        totalElements: 0,
        accessibleElements: 0,
        trapTests: [],
        skipLinkTests: []
    };

    // Get all focusable elements
    const focusableElements = await page.evaluate(() => {
        const selector = [
            'a[href]',
            'button',
            'input:not([disabled])',
            'textarea:not([disabled])',
            'select:not([disabled])',
            '[tabindex]:not([tabindex="-1"])',
            '[contenteditable="true"]'
        ].join(', ');

        return Array.from(document.querySelectorAll(selector)).map(el => ({
            tagName: el.tagName,
            id: el.id,
            className: el.className,
            tabIndex: el.tabIndex,
            hasAriaLabel: !!el.getAttribute('aria-label'),
            hasAriaLabelledBy: !!el.getAttribute('aria-labelledby')
        }));
    });

    navigationResults.totalElements = focusableElements.length;

    // Test tab navigation through all elements
    for (let i = 0; i < focusableElements.length; i++) {
        await page.keyboard.press('Tab');

        const currentFocus = await page.evaluate(() => {
            const el = document.activeElement;
            return {
                tagName: el.tagName,
                className: el.className,
                visible: !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length)
            };
        });

        if (currentFocus.visible) {
            navigationResults.accessibleElements++;
        }
    }

    // Test skip links
    await page.keyboard.press('Tab');
    const skipLinkVisible = await page.evaluate(() => {
        const skipLink = document.querySelector('a[href="#main"], a[href="#content"]');
        return skipLink && skipLink === document.activeElement;
    });

    navigationResults.skipLinkTests.push({
        hasSkipLink: skipLinkVisible,
        recommendation: skipLinkVisible ? 'Skip link found and accessible' : 'Consider adding skip link for better navigation'
    });

    return navigationResults;
}
```

#### Focus Management Testing
```javascript
async function testFocusManagement(page) {
    const focusTests = [];

    // Test modal focus trapping
    const modalButtons = await page.$$('[data-toggle="modal"], [data-bs-toggle="modal"]');

    for (const button of modalButtons) {
        await button.click();
        await page.waitForTimeout(500); // Wait for modal animation

        const focusTrapped = await page.evaluate(() => {
            const modal = document.querySelector('.modal:not(.fade)');
            if (!modal) return false;

            // Check if focus is trapped within modal
            const focusableElements = modal.querySelectorAll(
                'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
            );

            // Test Tab navigation within modal
            return focusableElements.length > 0 && modal.contains(document.activeElement);
        });

        focusTests.push({
            type: 'modal_focus_trap',
            passed: focusTrapped,
            element: 'modal',
            recommendation: focusTrapped ? 'Modal focus is properly trapped' : 'Modal should trap focus within dialog'
        });

        // Close modal
        await page.keyboard.press('Escape');
        await page.waitForTimeout(500);
    }

    return focusTests;
}
```

### 3. Understandable Content Testing

#### Form Label Testing
```javascript
async function testFormAccessibility(page) {
    const formResults = await page.evaluate(() => {
        const forms = document.querySelectorAll('form');
        const issues = [];

        forms.forEach((form, formIndex) => {
            const inputs = form.querySelectorAll('input, textarea, select');

            inputs.forEach((input, inputIndex) => {
                const inputId = input.id;
                const inputName = input.name;
                const inputType = input.type;

                // Check for proper labeling
                let hasLabel = false;
                let labelText = '';

                // Check for explicit label
                const label = document.querySelector(`label[for="${inputId}"]`);
                if (label) {
                    hasLabel = true;
                    labelText = label.textContent.trim();
                }

                // Check for aria-label
                if (!hasLabel && input.getAttribute('aria-label')) {
                    hasLabel = true;
                    labelText = input.getAttribute('aria-label');
                }

                // Check for aria-labelledby
                if (!hasLabel && input.getAttribute('aria-labelledby')) {
                    const labelElement = document.getElementById(input.getAttribute('aria-labelledby'));
                    if (labelElement) {
                        hasLabel = true;
                        labelText = labelElement.textContent.trim();
                    }
                }

                if (!hasLabel) {
                    issues.push({
                        type: 'missing_label',
                        form: formIndex,
                        input: inputIndex,
                        inputType: inputType,
                        inputName: inputName,
                        issue: 'Form control missing accessible label'
                    });
                }

                // Check for required field indication
                if (input.required && !input.getAttribute('aria-required')) {
                    issues.push({
                        type: 'missing_required_indicator',
                        form: formIndex,
                        input: inputIndex,
                        inputType: inputType,
                        issue: 'Required field not properly indicated'
                    });
                }

                // Check for error message association
                const errorMessage = form.querySelector(`[aria-describedby="${inputId}"], .error-message`);
                if (!errorMessage && input.getAttribute('aria-invalid') === 'true') {
                    issues.push({
                        type: 'missing_error_association',
                        form: formIndex,
                        input: inputIndex,
                        issue: 'Error message not associated with form control'
                    });
                }
            });
        });

        return issues;
    });

    return formResults;
}
```

### 4. Robust Content Testing

#### Semantic HTML Testing
```javascript
async function testSemanticStructure(page) {
    const structureResults = await page.evaluate(() => {
        const issues = [];

        // Check heading hierarchy
        const headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
        let previousLevel = 0;

        headings.forEach((heading, index) => {
            const currentLevel = parseInt(heading.tagName.charAt(1));

            if (index === 0 && currentLevel !== 1) {
                issues.push({
                    type: 'heading_hierarchy',
                    element: heading.tagName,
                    issue: 'Page should start with h1'
                });
            }

            if (currentLevel - previousLevel > 1) {
                issues.push({
                    type: 'heading_hierarchy',
                    element: heading.tagName,
                    issue: `Heading level skipped (${previousLevel} to ${currentLevel})`
                });
            }

            previousLevel = currentLevel;
        });

        // Check for proper landmarks
        const landmarks = {
            main: document.querySelector('main, [role="main"]'),
            nav: document.querySelector('nav, [role="navigation"]'),
            banner: document.querySelector('header, [role="banner"]'),
            contentinfo: document.querySelector('footer, [role="contentinfo"]')
        };

        Object.entries(landmarks).forEach(([landmark, element]) => {
            if (!element) {
                issues.push({
                    type: 'missing_landmark',
                    landmark: landmark,
                    issue: `Missing ${landmark} landmark`
                });
            }
        });

        // Check for proper button vs link usage
        const buttons = document.querySelectorAll('button, [role="button"]');
        const links = document.querySelectorAll('a[href]');

        buttons.forEach(button => {
            if (button.getAttribute('href')) {
                issues.push({
                    type: 'semantic_misuse',
                    element: 'button',
                    issue: 'Button element should not have href attribute'
                });
            }
        });

        return issues;
    });

    return structureResults;
}
```

## CFWheels-Specific Accessibility Patterns

### 1. Form Helper Accessibility
```cfm
<!-- Accessible form patterns with CFWheels -->
<cfoutput>
<form>
    <!-- Proper label association -->
    <div class="form-group">
        <label for="user-firstName">First Name *</label>
        #textField(objectName="user", property="firstName",
                   id="user-firstName",
                   required=true,
                   ariaRequired=true,
                   ariaDescribedBy="firstName-help",
                   label=false)#
        <div id="firstName-help" class="help-text">Enter your first name</div>

        <cfif user.hasErrors("firstName")>
            <div class="error-message" role="alert" aria-live="polite">
                #user.errorsOn("firstName")#
            </div>
        </cfif>
    </div>

    <!-- Fieldset for grouped controls -->
    <fieldset>
        <legend>Contact Preferences</legend>
        #radioButton(objectName="user", property="contactMethod",
                     tagValue="email", label="Email",
                     ariaDescribedBy="contact-help")#
        #radioButton(objectName="user", property="contactMethod",
                     tagValue="phone", label="Phone")#
        <div id="contact-help" class="help-text">Choose your preferred contact method</div>
    </fieldset>

    <!-- Submit button with descriptive text -->
    #submitTag(value="Create User Account", class="btn btn-primary", ariaDescribedBy="submit-help")#
    <div id="submit-help" class="sr-only">This will create your user account</div>
</form>
</cfoutput>
```

### 2. Data Table Accessibility
```cfm
<cfoutput>
<cfif users.recordCount gt 0>
    <table role="table" aria-label="User Management">
        <caption>List of #users.recordCount# registered users</caption>
        <thead>
            <tr>
                <th scope="col" id="name-header">Name</th>
                <th scope="col" id="email-header">Email</th>
                <th scope="col" id="status-header">Status</th>
                <th scope="col" id="actions-header">Actions</th>
            </tr>
        </thead>
        <tbody>
            <cfloop query="users">
                <tr>
                    <td headers="name-header">#users.firstName# #users.lastName#</td>
                    <td headers="email-header">#users.email#</td>
                    <td headers="status-header">
                        <span class="badge" aria-label="User status: #users.status#">
                            #users.status#
                        </span>
                    </td>
                    <td headers="actions-header">
                        #linkTo(controller="users", action="show", key=users.id,
                                text="View", ariaLabel="View user #users.firstName# #users.lastName#")#
                        #linkTo(controller="users", action="edit", key=users.id,
                                text="Edit", ariaLabel="Edit user #users.firstName# #users.lastName#")#
                    </td>
                </tr>
            </cfloop>
        </tbody>
    </table>
<cfelse>
    <div role="status" aria-live="polite">
        <p>No users found.</p>
    </div>
</cfif>
</cfoutput>
```

## Integration with wheels_execute Testing

### Accessibility Testing Phase
```javascript
async function runAccessibilityTests(url) {
    console.log('🔍 Running accessibility tests...');

    await mcp__puppeteer__puppeteer_navigate({url: url});

    const results = {
        colorContrast: await testColorContrast(page),
        keyboardNavigation: await testKeyboardNavigation(page),
        imageAccessibility: await testImageAccessibility(page),
        formAccessibility: await testFormAccessibility(page),
        semanticStructure: await testSemanticStructure(page),
        focusManagement: await testFocusManagement(page)
    };

    // Generate accessibility report
    const report = generateAccessibilityReport(results);

    // Validate against WCAG standards
    const wcagValidation = validateWCAGCompliance(results);

    return {
        results,
        report,
        wcagCompliant: wcagValidation.compliant,
        issues: wcagValidation.issues,
        score: calculateAccessibilityScore(results)
    };
}

function generateAccessibilityReport(results) {
    const issues = [];
    const successes = [];

    // Process all test results
    Object.entries(results).forEach(([testType, testResults]) => {
        if (Array.isArray(testResults) && testResults.length > 0) {
            testResults.forEach(issue => issues.push({...issue, testType}));
        } else if (testResults.passed === false) {
            issues.push({...testResults, testType});
        } else {
            successes.push({testType, status: 'passed'});
        }
    });

    return {
        totalTests: Object.keys(results).length,
        issuesFound: issues.length,
        testsPassedFace: successes.length,
        issues,
        recommendations: generateRecommendations(issues)
    };
}
```

## Automated Accessibility Testing Integration

### wheels_execute Integration
Add this to Phase 4 (Testing) in the wheels_execute command:

```markdown
#### 4.3 Accessibility Testing (MANDATORY)
- WCAG 2.1 AA compliance validation
- Color contrast verification (4.5:1 minimum)
- Keyboard navigation testing
- Screen reader compatibility verification
- Form accessibility validation
- Semantic HTML structure verification
- Focus management testing
- Image alt text validation

**Success Criteria:**
- ✅ All color contrasts meet WCAG AA standards (4.5:1)
- ✅ All interactive elements are keyboard accessible
- ✅ All forms have proper labels and error associations
- ✅ Semantic HTML structure is present (headings, landmarks)
- ✅ All images have appropriate alt text
- ✅ Focus is properly managed in dynamic content
- ✅ Overall accessibility score >= 95/100
```

## Tools and Resources

### Recommended Testing Tools
- **aXe-core**: Automated accessibility testing engine
- **WAVE**: Web accessibility evaluation tool
- **Color Contrast Analyzers**: For manual contrast checking
- **Screen Readers**: NVDA, JAWS, VoiceOver for user testing
- **Lighthouse**: Accessibility auditing in Chrome DevTools

### CFWheels Accessibility Helpers
Consider creating custom helpers for common accessibility patterns:

```cfm
<!-- Custom accessibility helpers -->
<cfscript>
function accessibleTextField(objectName, property, options={}) {
    // Add default accessibility attributes
    options.ariaRequired = options.required ?: false;
    options.ariaInvalid = model(objectName).hasErrors(property);

    if (options.ariaInvalid) {
        options.ariaDescribedBy = "#property#-error";
    }

    return textField(argumentCollection=options);
}

function accessibleLink(text, options={}) {
    // Ensure descriptive link text
    if (len(trim(text)) < 4) {
        options.ariaLabel = options.ariaLabel ?: "Link: #text#";
    }

    return linkTo(argumentCollection=options, text=text);
}
</cfscript>
```

This comprehensive accessibility testing framework ensures that CFWheels applications are usable by everyone, meeting modern web standards and legal requirements.