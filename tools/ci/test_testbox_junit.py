"""Tests for tools/ci/testbox_junit.py (#3901). Run: python3 tools/ci/test_testbox_junit.py"""
import importlib.util
import os
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("testbox_junit", os.path.join(HERE, "testbox_junit.py"))
tj = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(tj)


def spec(name, status="Passed", **extra):
    return dict(name=name, status=status, totalDuration=5, **extra)


def suite(name, specs=(), children=()):
    return {"name": name, "specStats": list(specs), "suiteStats": list(children)}


def bundle(name, *suites):
    total = 0

    def count(s):
        return len(s["specStats"]) + sum(count(c) for c in s["suiteStats"])

    total = sum(count(s) for s in suites)
    return {"name": name, "totalSpecs": total, "totalFail": 0, "totalError": 0,
            "totalDuration": 10, "suiteStats": list(suites)}


def result(*bundles):
    return {"totalSpecs": sum(b["totalSpecs"] for b in bundles), "totalFail": 0,
            "totalError": 0, "totalDuration": 20, "bundleStats": list(bundles)}


def identities(root):
    return [(tc.get("classname"), tc.get("name")) for tc in root.iter("testcase")]


class ConvertTests(unittest.TestCase):

    def test_same_describe_and_it_in_two_bundles_stay_distinct(self):
        # The JUnit publisher merges test cases with the same classname and name,
        # so these two specs used to count as one in the PR comment.
        r = result(
            bundle("specs.a.FirstSpec", suite("supports()", [spec("returns true")])),
            bundle("specs.b.SecondSpec", suite("supports()", [spec("returns true")])),
        )
        ids = identities(tj.convert(r, "lucee7/sqlite"))
        self.assertEqual(len(ids), 2)
        self.assertEqual(len(set(ids)), 2)

    def test_same_inner_describe_under_different_outer_describes_stay_distinct(self):
        r = result(bundle("specs.ThirdSpec",
            suite("on create", children=[suite("validation", [spec("fails")])]),
            suite("on update", children=[suite("validation", [spec("fails")])]),
        ))
        ids = identities(tj.convert(r, "lucee7/sqlite"))
        self.assertEqual(len(set(ids)), 2)

    def test_repeated_it_label_in_one_describe_stays_distinct(self):
        r = result(bundle("specs.FourthSpec", suite("x", [spec("same"), spec("same")])))
        ids = identities(tj.convert(r, "lucee7/sqlite"))
        self.assertEqual(len(set(ids)), 2)

    def test_testcase_count_equals_total_specs(self):
        r = result(
            bundle("specs.a.FirstSpec", suite("s", [spec("one"), spec("two")])),
            bundle("specs.b.SecondSpec", suite("s", [spec("one")], [suite("t", [spec("one")])])),
        )
        root = tj.convert(r, "adobe2025/mysql")
        self.assertEqual(len(list(root.iter("testcase"))), r["totalSpecs"])
        self.assertEqual(root.get("tests"), str(r["totalSpecs"]))

    def test_statuses_map_to_junit_elements(self):
        r = result(bundle("specs.StatusSpec", suite("s", [
            spec("p"),
            spec("f", "Failed", failMessage="boom", failDetail="detail"),
            spec("e", "Error", failMessage="err"),
            spec("k", "Skipped"),
        ])))
        cases = {tc.get("name"): tc for tc in tj.convert(r, "boxlang/h2").iter("testcase")}
        self.assertEqual(len(list(cases["p"])), 0)
        self.assertEqual(cases["f"].find("failure").get("message"), "boom")
        self.assertEqual(cases["f"].find("failure").text, "detail")
        self.assertEqual(cases["e"].find("error").get("message"), "err")
        self.assertIsNotNone(cases["k"].find("skipped"))

    def test_classname_keeps_the_engine_and_database_prefix(self):
        r = result(bundle("specs.PrefixSpec", suite("s", [spec("one")])))
        (classname, _), = identities(tj.convert(r, "rustcfml/sqlite"))
        self.assertTrue(classname.startswith("rustcfml/sqlite :: "))

    def test_unreadable_result_file_writes_nothing_and_exits_zero(self):
        out = os.path.join(HERE, "_missing_junit_test.xml")
        self.assertEqual(tj.main([os.path.join(HERE, "no-such-result.json"), out, "x/y"]), 0)
        self.assertFalse(os.path.exists(out))


if __name__ == "__main__":
    unittest.main()
