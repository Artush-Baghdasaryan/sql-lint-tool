# See SQLFluff custom rules guide:
# https://docs.sqlfluff.com/en/stable/guides/setup/developing_custom_rules.html

import re
from sqlfluff.core.rules import BaseRule, LintResult
from sqlfluff.core.rules.crawlers import SegmentSeekerCrawler
from sqlfluff.core.rules.fix import LintFix
from sqlfluff.core.parser.segments.raw import RawSegment

SYSTEM_SCHEMAS = ("sys", "information_schema")
FUNCTION_LIKE = ("openjson", "openquery", "openrowset", "opendatasource")
SYSTEM_OBJECTS_UNQUALIFIED = {"sysobjects", "sysindexes", "syscolumns", "systypes", "sysusers", "syscomments"}

_SIMPLE_IDENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


class Rule_DBO_LL11(BaseRule):
    """Require schema qualification for user table references (e.g. dbo.Table)."""

    
    groups = ("all",)
    crawl_behaviour = SegmentSeekerCrawler({"table_reference"})
    _works_on_unparsable = False
    is_fix_compatible = True

    def _eval(self, context):
        seg = context.segment
        raw = seg.raw.strip()
        raw_l = raw.lower()

        # Ignore temp tables and table vars
        if raw_l.startswith("#") or raw_l.startswith("@"):
            return None

        # Ignore already-qualified or cross-db refs
        if "." in raw:
            return None

        # Ignore system schemas if already schema-qualified (handled above) + legacy system objects
        if raw_l.startswith(SYSTEM_SCHEMAS) or raw_l in SYSTEM_OBJECTS_UNQUALIFIED:
            return None

        # Ignore function-like rowsets
        for fn in FUNCTION_LIKE:
            if raw_l.startswith(fn + "(") or raw_l.startswith(fn + " "):
                return None

        # Find the identifier segment inside the table_reference.
        # In tsql it’s usually 'naked_identifier' or 'quoted_identifier' or 'bracketed_identifier'.
        ident = None
        for t in ("naked_identifier", "quoted_identifier", "bracketed_identifier"):
            found = next(seg.recursive_crawl(t), None)
            if found is not None:
                ident = found
                break

        # If we can't confidently locate a safe identifier, lint only (no fix).
        fixes = []
        if ident is not None:
            # Only auto-fix truly simple unqualified names (avoid odd cases).
            # For bracketed/quoted identifiers, this still works because we insert before them.
            if _SIMPLE_IDENT_RE.match(ident.raw.strip("[]")):
                fixes = [
                    LintFix.create_before(
                        anchor_segment=ident,
                        edit_segments=[RawSegment(raw="dbo"), RawSegment(raw=".")],
                    )
                ]

        return LintResult(
            anchor=seg,
            description=f"Unqualified table reference '{raw}'. Use schema qualification (e.g. dbo.{raw}).",
            fixes=fixes,
        )
