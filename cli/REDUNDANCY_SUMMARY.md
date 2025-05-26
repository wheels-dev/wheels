# Wheels CLI Redundancy Summary

## Actual Redundancies Found

### 1. Security Commands
- **`wheels analyze security`** → Redundant with **`wheels security scan`**
- Action taken: Deprecated with forward to new command

### 2. Performance Commands  
- **`wheels analyze performance`** → Partial overlap with **`wheels optimize performance`**
- Recommendation: Keep both but clarify:
  - `analyze performance`: Detection and reporting
  - `optimize performance`: Actual optimization

### 3. Test Commands
- **`wheels test`** → Different from **`wheels test run`**
  - Original: Runs Wheels framework tests via HTTP
  - New: Runs TestBox tests directly
  - Action: Keep both - they serve different purposes

### 4. Resource Generation
- **`wheels scaffold`** → Partial overlap with **`wheels generate resource`**
- Differences:
  - `scaffold`: Traditional MVC with individual commands
  - `generate resource`: Modern REST resource generation
- Action: Both refactored to use services, kept for different use cases

## Commands That Are NOT Redundant

1. **`wheels test`** - Framework test runner (HTTP-based)
2. **`wheels test run`** - Application test runner (TestBox)
3. **`wheels dbmigrate/*`** - Unique migration functionality
4. **`wheels docs/*`** - Unique documentation generation
5. **`wheels env/*`** - Unique environment management
6. **`wheels plugins/*`** - Enhanced but not replacing `deps`

## Recommendations

### Immediate Actions
1. ✅ Deprecated `analyze security` → forwards to `security scan`
2. Keep other commands as they serve different purposes

### Future Considerations
1. Consider merging `analyze performance` and `optimize performance`
2. Consider consolidating all `analyze/*` commands under unified interface
3. Add clear documentation explaining the differences between similar commands

### Why Keep Similar Commands
- **Different audiences**: Some prefer traditional scaffolding, others REST
- **Different contexts**: Framework tests vs application tests  
- **Backward compatibility**: Existing projects rely on these commands
- **Progressive enhancement**: New commands add features without breaking old workflows