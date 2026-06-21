#!/usr/bin/env python3
"""Generate migration 022 from dsa_mastery_system.docx."""
import json
import re
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

DOCX = Path(r"c:\Users\Admin\Downloads\dsa_mastery_system.docx")
OUT = Path(__file__).resolve().parents[1] / "migrations" / "022_dsa_mastery_daily_program.sql"

W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"

PATTERN_ENTITY = {
    1: "c000000c-0001-4001-8001-000000000003",
    2: "c000000c-0001-4001-8001-000000000004",
    3: "c000000c-0001-4001-8001-000000000005",
    4: "c000000c-0001-4001-8001-000000000006",
    5: "c000000c-0001-4001-8001-000000000007",
    6: "c000000c-0001-4001-8001-000000000008",
    7: "c000000c-0001-4001-8001-000000000009",
    8: "c000000c-0001-4001-8001-000000000010",
    9: "c000000c-0001-4001-8001-000000000011",
    10: "c000000c-0001-4001-8001-000000000012",
    11: "c000000c-0001-4001-8001-000000000013",
    12: "c000000c-0001-4001-8001-000000000014",
    13: "c000000c-0001-4001-8001-000000000015",
    14: "c000000c-0001-4001-8001-000000000016",
    15: "c000000c-0001-4001-8001-000000000017",
    16: "c000000c-0001-4001-8001-000000000018",
    17: "c000000c-0001-4001-8001-000000000019",
    18: "c000000c-0001-4001-8001-000000000020",
    19: "c000000c-0001-4001-8001-000000000021",
    20: "c000000c-0001-4001-8001-000000000022",
}

ROADMAP = {
    10: ("Tree BFS", "Level-order queue traversal for right-side views, minimum depth, zigzag order."),
    11: ("Binary Search Tree", "Validate, insert, delete, and in-order properties for efficient tree operations."),
    12: ("Binary Search on Answer", "Search answer space when feasibility predicate is monotonic."),
    13: ("Graph DFS & BFS", "Connected components, islands, flood fill, unweighted shortest paths."),
    14: ("Topological Sort", "Kahn's algorithm or DFS post-order for DAG ordering."),
    15: ("Union Find (DSU)", "Path compression and rank for dynamic connectivity."),
    16: ("Shortest Path", "Dijkstra, Bellman-Ford, BFS on weighted/unweighted graphs."),
    17: ("Dynamic Programming", "1D, 2D, interval, tree DP, knapsack state transitions."),
    18: ("Backtracking", "Permutations, combinations, N-Queens, constraint satisfaction."),
    19: ("Greedy", "Activity selection, interval scheduling, locally optimal proofs."),
    20: ("Trie", "Prefix matching, autocomplete, word search, IP routing."),
}


def extract_paras(docx: Path) -> list[str]:
    with zipfile.ZipFile(docx) as z:
        root = ET.fromstring(z.read("word/document.xml"))
    paras = []
    for p in root.iter(W + "p"):
        texts = [t.text for t in p.iter(W + "t") if t.text]
        if texts:
            paras.append("".join(texts))
    return paras


def parse_patterns(paras: list[str]) -> dict[int, dict]:
    patterns = {}
    current = None
    for line in paras:
        m = re.match(r"^(\d+)️⃣\s+(.+)$", line.strip())
        if m:
            current = int(m.group(1))
            patterns[current] = {"name": m.group(2).strip(), "lines": []}
        elif current:
            patterns[current]["lines"].append(line)

    result = {}
    for num, p in patterns.items():
        lines = p["lines"]
        when, signals, strategy = [], [], []
        template = []
        problems = []
        section = None
        for i, line in enumerate(lines):
            s = line.strip()
            if s == "When to Use":
                section = "when"
                continue
            if s == "Recognition Signals":
                section = "signals"
                continue
            if s == "E.  Practice Strategy" or s.startswith("E.  Practice"):
                section = "strategy"
                continue
            if s == "Code Template":
                section = "template"
                continue
            if s in ("Common Variants", "Common Mistakes & Edge Cases", "B.  Implementation Guide"):
                if section == "template" and template:
                    section = None
                continue
            if section == "when" and s and not s.startswith("Intuition"):
                when.append(s)
            elif section == "signals" and s and not s.startswith("Complexity"):
                signals.append(s)
            elif section == "strategy" and s:
                strategy.append(s)
            elif section == "template":
                if s.startswith("def ") or s.startswith("    ") or s == "return result":
                    template.append(line.rstrip())

        for line in lines:
            if "LeetCode #" in line:
                m = re.search(r"LeetCode #(\d+)", line)
                if m:
                    problems.append(f"LC{m.group(1)}")

        result[num] = {
            "name": p["name"],
            "when_to_use": " ".join(when[:5])[:500],
            "recognition_signals": signals[:6],
            "practice_strategy": " ".join(strategy[:4])[:400],
            "code_template": "\n".join(template[:20]),
            "problems": list(dict.fromkeys(problems))[:12],
        }
    return result


def sql_str(s: str) -> str:
    return s.replace("'", "''")


def sql_dollar(s: str, prefix: str = "j") -> str:
    """PostgreSQL dollar-quoted literal — safe for JSON with quotes/backslashes."""
    tag = prefix
    n = 0
    while f"${tag}$" in s:
        n += 1
        tag = f"{prefix}{n}"
    return f"${tag}${s}${tag}$"


def main():
    paras = extract_paras(DOCX)
    parsed = parse_patterns(paras)

    lines = [
        "-- DSA Mastery daily program — enriched from dsa_mastery_system.docx",
        "--",
        "-- Run from backend/ directory (NOT by pasting Python into psql):",
        "--   psql \"$DATABASE_URL\" -v ON_ERROR_STOP=1 -f migrations/022_dsa_mastery_daily_program.sql",
        "--",
        "ALTER TABLE learning_schedules",
        "    ADD COLUMN IF NOT EXISTS dsa_program_start DATE DEFAULT CURRENT_DATE;",
        "",
        "DO $$",
        "DECLARE",
        "    admin_id UUID;",
        "    owner_email TEXT := 'mphuc8671@gmail.com';",
        "BEGIN",
        "    SELECT id INTO admin_id FROM users",
        "    WHERE lower(trim(email)) = lower(trim(owner_email)) LIMIT 1;",
        "    IF admin_id IS NULL THEN",
        "        RAISE NOTICE 'Owner % not found — skip DSA program seed', owner_email;",
        "        RETURN;",
        "    END IF;",
        "",
        "    UPDATE learning_schedules SET dsa_program_start = COALESCE(dsa_program_start, CURRENT_DATE)",
        "    WHERE user_id = admin_id;",
        "",
    ]

    for order in range(1, 21):
        eid = PATTERN_ENTITY[order]
        if order in parsed:
            d = parsed[order]
            name = d["name"]
            content = (
                f"Pattern {order}/20 — {name}. "
                f"When to use: {d['when_to_use'][:200]}. "
                f"Practice: {d['practice_strategy'][:180]}. "
                f"Target 10+ LeetCode problems; recognize pattern in <60s."
            )
            meta = {
                "track": "dsa",
                "pattern_order": order,
                "pattern_slug": re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-"),
                "when_to_use": d["when_to_use"],
                "recognition_signals": d["recognition_signals"],
                "practice_strategy": d["practice_strategy"],
                "code_template": d["code_template"],
                "problems": d["problems"],
                "benchmark_easy_min": 8,
                "benchmark_medium_min": 20,
                "benchmark_hard_min": 35,
                "source_doc": "dsa_mastery_system.docx",
            }
        else:
            title, desc = ROADMAP[order]
            name = title
            content = f"Pattern {order}/20 — {title}. {desc} Target 10+ LeetCode problems."
            meta = {
                "track": "dsa",
                "pattern_order": order,
                "pattern_slug": re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-"),
                "when_to_use": desc,
                "benchmark_easy_min": 8,
                "benchmark_medium_min": 20,
                "benchmark_hard_min": 35,
                "source_doc": "dsa_mastery_system.docx",
            }

        meta_json = json.dumps(meta, ensure_ascii=False)
        lines.append(f"    UPDATE entities SET")
        lines.append(f"        title = '{sql_str(name)}',")
        lines.append(f"        content = '{sql_str(content)}',")
        lines.append(f"        metadata = metadata || {sql_dollar(meta_json, f'm{order}')}::jsonb,")
        lines.append(f"        updated_at = NOW()")
        lines.append(f"    WHERE id = '{eid}'::uuid AND user_id = admin_id;")
        lines.append("")

    # course + roadmap + new guides
    guides = [
        (
            "c000000c-0001-4001-8001-000000000001",
            "learning_course",
            "DSA Mastery System",
            "10-week Mid→Senior curriculum from dsa_mastery_system.docx: 20 patterns, 150–200 problems, daily learn/practice/review/mock cycles, STAR mock interviews, and week-by-week benchmarks.",
            {"track": "dsa", "weeks": 10, "target_problems": 200, "program_version": 2},
        ),
        (
            "c000000c-0001-4001-8001-000000000002",
            "learning_topic",
            "10-Week DSA Roadmap",
            "Phase 1 (W1–2): Two Ptr, HashMap, Prefix, Sliding, BS — 3–4 problems/day. Phase 2 (W3–5): Stack, Heap, Lists, Trees, Graph basics — 4–5/day. Phase 3 (W6–8): Topo, DSU, Dijkstra, DP, Backtrack, Greedy, Trie — morning+evening. Phase 4 (W9–10): timed pairs + full mocks.",
            {"track": "dsa", "phase": "roadmap", "weeks": "1-10", "program_version": 2},
        ),
        (
            "c000000c-0001-4001-8001-000000000030",
            "learning_topic",
            "DSA Mock Interview (STAR)",
            "UNDERSTAND 2–3m → EXAMPLES 2m → APPROACH 3–5m → CODE 15–20m → TEST 3–5m → COMPLEXITY 1m. Timed: 45min/2 problems or 90min/3. No hints. Talk aloud.",
            {"track": "dsa", "phase": "mock", "kind": "mock_framework"},
        ),
        (
            "c000000c-0001-4001-8001-000000000031",
            "learning_topic",
            "DSA Progress Benchmarks",
            "W2: Easy <10min, recognize Two Ptr/Sliding <2min. W5: Medium <25min, 80+ problems. W8: Hard <40min, 130+ problems. W10: 2 Medium in 45min, 160–200 total, 7/10 mock pass rate.",
            {"track": "dsa", "phase": "metrics", "kind": "benchmarks"},
        ),
    ]

    for i, (eid, etype, title, content, meta) in enumerate(guides):
        meta_json = json.dumps(meta, ensure_ascii=False)
        lines.append(f"    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)")
        lines.append(f"    VALUES ('{eid}'::uuid, admin_id, '{etype}', '{sql_str(title)}',")
        lines.append(f"     '{sql_str(content)}', '[\"dsa\"]'::jsonb, 'learning_seed', {sql_dollar(meta_json, f'g{i}')}::jsonb, 'learning', 'active')")
        lines.append(f"    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content,")
        lines.append(f"        metadata = entities.metadata || EXCLUDED.metadata, updated_at = NOW();")
        lines.append("")

    lines.extend([
        "    RAISE NOTICE 'DSA mastery daily program applied for %', owner_email;",
        "END $$;",
        "",
    ])

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT} ({len(lines)} lines)")


if __name__ == "__main__":
    main()
