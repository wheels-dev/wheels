"""Convert a TestBox JSON result into JUnit XML for the compatibility matrix (#3901).

Run: python3 tools/ci/testbox_junit.py <result.json> <junit.xml> <engine/db>

Used by .github/workflows/compat-matrix.yml. A missing or unreadable result
file is not an error here: the workflow's own result checks decide pass/fail.
"""
import json
import re
import sys
from xml.etree.ElementTree import Element, SubElement, tostring

# C0 control characters other than tab, newline and carriage return aren't
# allowed in XML 1.0; a spec message or debug output can carry them.
_XML_INVALID = re.compile("[\x00-\x08\x0b\x0c\x0e-\x1f]")


def safe_str(val, default=""):
    """Coerce None/null JSON values to string and drop XML-invalid characters."""
    return _XML_INVALID.sub("", str(val)) if val is not None else default


def _ms(val):
    return str((val or 0) / 1000)


def process_suite(parent_el, suite, classname_base, path, seen):
    """Recursively process suites (TestBox suites can be nested).

    The classname carries the bundle and the whole describe path, not just the
    innermost describe: the JUnit publisher merges test cases with the same
    classname and name, so two specs with the same describe and it() labels in
    different bundles (or under different outer describes) used to count as
    one. A label repeated inside one describe gets a " (2)", " (3)" suffix.
    """
    path = path + [safe_str(suite.get("name"))]
    classname = f"{classname_base} :: {' > '.join(path)}"
    for sp in suite.get("specStats", []):
        name = safe_str(sp.get("name"))
        seen[(classname, name)] = seen.get((classname, name), 0) + 1
        if seen[(classname, name)] > 1:
            name = f"{name} ({seen[(classname, name)]})"
        tc = SubElement(parent_el, "testcase",
            name=name,
            classname=classname,
            time=_ms(sp.get("totalDuration")))
        status = sp.get("status")
        if status == "Failed":
            f = SubElement(tc, "failure", message=safe_str(sp.get("failMessage")))
            f.text = safe_str(sp.get("failDetail"))
        elif status == "Error":
            e = SubElement(tc, "error", message=safe_str(sp.get("failMessage")))
            e.text = safe_str(sp.get("failDetail"))
        elif status == "Skipped":
            SubElement(tc, "skipped")
    for child in suite.get("suiteStats", []):
        process_suite(parent_el, child, classname_base, path, seen)


def convert(result, prefix):
    root = Element("testsuites",
        name=prefix,
        tests=str(int(result.get("totalSpecs", 0))),
        failures=str(int(result.get("totalFail", 0))),
        errors=str(int(result.get("totalError", 0))),
        time=_ms(result.get("totalDuration")))
    for b in result.get("bundleStats", []):
        ts = SubElement(root, "testsuite",
            name=f"{prefix} :: {b.get('name', '')}",
            tests=str(int(b.get("totalSpecs", 0))),
            failures=str(int(b.get("totalFail", 0))),
            errors=str(int(b.get("totalError", 0))),
            time=_ms(b.get("totalDuration")))
        seen = {}
        for s in b.get("suiteStats", []):
            process_suite(ts, s, f"{prefix} :: {b.get('name', '')}", [], seen)
    return root


def main(argv):
    result_file, junit_file, prefix = argv
    try:
        with open(result_file) as fh:
            # strict=False: TestBox output can hold raw control characters in
            # strings, and a strict parse would drop the whole leg.
            result = json.load(fh, strict=False)
    except Exception:
        return 0
    with open(junit_file, "wb") as fh:
        fh.write(b'<?xml version="1.0" encoding="UTF-8"?>')
        fh.write(tostring(convert(result, prefix)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
