-- DSA Mastery daily program — enriched from dsa_mastery_system.docx
--
-- Run from backend/ directory (NOT by pasting Python into psql):
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/022_dsa_mastery_daily_program.sql
--
ALTER TABLE learning_schedules
    ADD COLUMN IF NOT EXISTS dsa_program_start DATE DEFAULT CURRENT_DATE;

DO $$
DECLARE
    admin_id UUID;
    owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(owner_email)) LIMIT 1;
    IF admin_id IS NULL THEN
        RAISE NOTICE 'Owner % not found — skip DSA program seed', owner_email;
        RETURN;
    END IF;

    UPDATE learning_schedules SET dsa_program_start = COALESCE(dsa_program_start, CURRENT_DATE)
    WHERE user_id = admin_id;

    UPDATE entities SET
        title = 'Two Pointers',
        content = 'Pattern 1/20 — Two Pointers. When to use: Finding pairs in sorted arrays that satisfy a condition Reversing or partitioning arrays in-place Detecting cycles in linked lists (slow/fast pointer) Comparing strings (palindrome, subsequence checks. Practice: Week 1: Solve Easy problems in one sitting, aiming for < 10 min each Week 2: Tackle Medium problems; identify the pointer movement rule before coding Revisit 3Sum and Sort Colors —. Target 10+ LeetCode problems; recognize pattern in <60s.',
        metadata = metadata || $m1${"track": "dsa", "pattern_order": 1, "pattern_slug": "two-pointers", "when_to_use": "Finding pairs in sorted arrays that satisfy a condition Reversing or partitioning arrays in-place Detecting cycles in linked lists (slow/fast pointer) Comparing strings (palindrome, subsequence checks) Merging two sorted arrays", "recognition_signals": ["Sorted array + pair/triplet sum problem", "\"Remove duplicates\", \"reverse\", \"palindrome\"", "Two arrays to compare simultaneously", "In-place modification required", "Intuition & Mental Model", "Imagine two readers starting at opposite ends of a book. If the clue you need is somewhere in the middle, they both walk toward each other and stop when they find it — instead of one reader starting over from the beginning each time."], "practice_strategy": "Week 1: Solve Easy problems in one sitting, aiming for < 10 min each Week 2: Tackle Medium problems; identify the pointer movement rule before coding Revisit 3Sum and Sort Colors — they appear in disguise in harder problems Target: recognize two-pointer signal within 60 seconds of reading a problem", "code_template": "def two_pointers(arr):\n    return result", "problems": ["LC167", "LC125", "LC344", "LC283", "LC977", "LC15", "LC11", "LC80", "LC75", "LC18", "LC42", "LC76"], "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m1$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000003'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Sliding Window',
        content = 'Pattern 2/20 — Sliding Window. When to use: Maximum/minimum/sum of subarray of size k Longest/shortest substring with a constraint Problems using phrases: ''contiguous'', ''substring'', ''subarray'' Frequency-based constraints (at most K distinct cha. Practice: Master fixed window first (3–4 easy/medium problems), then move to variable For each variable-window problem, write the INVALID condition before any code Revisit ''Minimum Window Su. Target 10+ LeetCode problems; recognize pattern in <60s.',
        metadata = metadata || $m2${"track": "dsa", "pattern_order": 2, "pattern_slug": "sliding-window", "when_to_use": "Maximum/minimum/sum of subarray of size k Longest/shortest substring with a constraint Problems using phrases: 'contiguous', 'substring', 'subarray' Frequency-based constraints (at most K distinct chars, anagram)", "recognition_signals": ["\"Contiguous subarray/substring\"", "\"Longest/shortest with condition\"", "\"At most K distinct elements\"", "Fixed window size k mentioned", "String permutation / anagram detection", "Intuition & Mental Model"], "practice_strategy": "Master fixed window first (3–4 easy/medium problems), then move to variable For each variable-window problem, write the INVALID condition before any code Revisit 'Minimum Window Substring' — it's the hardest and most instructive Target: pattern recognition < 90 seconds, coding < 20 minutes for medium", "code_template": "def sliding_window(s):\n    return result", "problems": ["LC643", "LC438", "LC3", "LC209", "LC340", "LC567", "LC904", "LC1004", "LC992", "LC76", "LC239", "LC424"], "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m2$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000004'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'HashMap / Frequency Counting',
        content = 'Pattern 3/20 — HashMap / Frequency Counting. When to use: Finding pairs, duplicates, or complements in O(n) Counting character/element frequencies Checking if two strings are anagrams Grouping elements by property (group anagrams) First unique/duplicate elem. Practice: Start with Two Sum — practice until you write it in < 3 minutes from memory Then practice ''Subarray Sum Equals K'' — the prefix-sum + hashmap combo is critical Group Anagrams: pract. Target 10+ LeetCode problems; recognize pattern in <60s.',
        metadata = metadata || $m3${"track": "dsa", "pattern_order": 3, "pattern_slug": "hashmap-frequency-counting", "when_to_use": "Finding pairs, duplicates, or complements in O(n) Counting character/element frequencies Checking if two strings are anagrams Grouping elements by property (group anagrams) First unique/duplicate element", "recognition_signals": ["\"Find a pair that...\"", "\"Contains duplicate\"", "\"Anagram\", \"permutation\"", "Count of something needed", "Need O(1) lookup after a single pass", "Intuition & Mental Model"], "practice_strategy": "Start with Two Sum — practice until you write it in < 3 minutes from memory Then practice 'Subarray Sum Equals K' — the prefix-sum + hashmap combo is critical Group Anagrams: practice both sorted-key and char-count-tuple approaches Set vs Map: always ask yourself — do I need the value or just membership?", "code_template": "def two_sum(nums, target):\ndef is_anagram(s, t):", "problems": ["LC1", "LC242", "LC217", "LC387", "LC383", "LC49", "LC560", "LC128", "LC454", "LC347", "LC76", "LC290"], "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m3$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000005'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Prefix Sum',
        content = 'Pattern 4/20 — Prefix Sum. When to use: Range sum queries on static arrays Subarray sum problems (equals k, divisible by k) 2D matrix range sum queries Problems needing cumulative aggregation. Practice: Start with LeetCode #303 and #560 — these two teach the core 1D patterns Practice the hashmap variant until you can write it without thinking Do LeetCode #304 for 2D prefix sum — d. Target 10+ LeetCode problems; recognize pattern in <60s.',
        metadata = metadata || $m4${"track": "dsa", "pattern_order": 4, "pattern_slug": "prefix-sum", "when_to_use": "Range sum queries on static arrays Subarray sum problems (equals k, divisible by k) 2D matrix range sum queries Problems needing cumulative aggregation", "recognition_signals": ["\"Subarray sum equals...\"", "Multiple range queries on same array", "\"Divisible by k\"", "Immutable array with sum queries", "2D matrix region sum", "Intuition & Mental Model"], "practice_strategy": "Start with LeetCode #303 and #560 — these two teach the core 1D patterns Practice the hashmap variant until you can write it without thinking Do LeetCode #304 for 2D prefix sum — draw diagrams to understand the formula Master modulo prefix sum (LeetCode #974) — this pattern appears in disguise often", "code_template": "def build_prefix(arr):\ndef range_sum(prefix, l, r):\ndef subarray_sum_k(nums, k):", "problems": ["LC303", "LC724", "LC1480", "LC560", "LC525", "LC974", "LC304", "LC238", "LC325", "LC2270", "LC327", "LC1314"], "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m4$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000006'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Binary Search',
        content = 'Pattern 5/20 — Binary Search. When to use: Searching in sorted array or rotated sorted array Finding minimum/maximum satisfying a condition Problems with "minimum possible maximum" or "maximum possible minimum" Searching in infinite or implici. Practice: Memorize BOTH templates (exact value and monotonic answer) word-for-word Solve Koko Eating Bananas and Ship Packages back-to-back — same structure Practice writing the feasibility . Target 10+ LeetCode problems; recognize pattern in <60s.',
        metadata = metadata || $m5${"track": "dsa", "pattern_order": 5, "pattern_slug": "binary-search", "when_to_use": "Searching in sorted array or rotated sorted array Finding minimum/maximum satisfying a condition Problems with \"minimum possible maximum\" or \"maximum possible minimum\" Searching in infinite or implicit sorted space", "recognition_signals": ["Sorted array or matrix", "\"Find minimum k such that condition(k) is true\"", "O(log n) time requirement mentioned", "Rotated sorted array", "\"At least / at most / feasible\"", "Intuition & Mental Model"], "practice_strategy": "Memorize BOTH templates (exact value and monotonic answer) word-for-word Solve Koko Eating Bananas and Ship Packages back-to-back — same structure Practice writing the feasibility function on paper before coding Target: recognize 'minimize maximum' or 'maximize minimum' signals instantly", "code_template": "def binary_search(arr, target):\ndef binary_search_answer(lo, hi):", "problems": ["LC704", "LC278", "LC35", "LC69", "LC33", "LC153", "LC74", "LC875", "LC1011", "LC162", "LC4", "LC410"], "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m5$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000007'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Stack & Monotonic Stack',
        content = 'Pattern 6/20 — Stack & Monotonic Stack. When to use: Bracket/parenthesis matching and validation Expression evaluation (postfix, operators) Next Greater Element / Previous Smaller Element Histogram largest rectangle problems Simplifying paths, undo oper. Practice: Master Valid Parentheses and Daily Temperatures first — they teach both stack types Then Largest Rectangle in Histogram — critical for senior interviews Practice explaining the ''ea. Target 10+ LeetCode problems; recognize pattern in <60s.',
        metadata = metadata || $m6${"track": "dsa", "pattern_order": 6, "pattern_slug": "stack-monotonic-stack", "when_to_use": "Bracket/parenthesis matching and validation Expression evaluation (postfix, operators) Next Greater Element / Previous Smaller Element Histogram largest rectangle problems Simplifying paths, undo operations", "recognition_signals": ["\"Next greater/smaller element\"", "Balanced parentheses, bracket matching", "\"Largest rectangle\" in histogram", "Monotonically increasing/decreasing windows", "Expression evaluation with operators", "Intuition & Mental Model"], "practice_strategy": "Master Valid Parentheses and Daily Temperatures first — they teach both stack types Then Largest Rectangle in Histogram — critical for senior interviews Practice explaining the 'each element pushed/popped once' O(n) proof Target: identify monotonic stack need within 2 minutes of reading problem", "code_template": "def next_greater(nums):\n    return result\ndef is_valid(s):", "problems": ["LC20", "LC155", "LC496", "LC739", "LC503", "LC316", "LC84", "LC42", "LC856", "LC735", "LC85", "LC907"], "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m6$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000008'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Heap / Priority Queue',
        content = 'Pattern 7/20 — Heap / Priority Queue. When to use: Finding Top K largest/smallest elements Merging K sorted lists/arrays Meeting room scheduling, task scheduling Dijkstra''s shortest path algorithm Streaming median or K-th largest dynamically. Practice: Week 1: LeetCode #703, #1046 — build heap intuition Week 2: K Closest, Top K Frequent, Merge K Sorted Lists — core patterns Week 3: Two-heap median, IPO — advanced combos Always pr. Target 10+ LeetCode problems; recognize pattern in <60s.',
        metadata = metadata || $m7${"track": "dsa", "pattern_order": 7, "pattern_slug": "heap-priority-queue", "when_to_use": "Finding Top K largest/smallest elements Merging K sorted lists/arrays Meeting room scheduling, task scheduling Dijkstra's shortest path algorithm Streaming median or K-th largest dynamically", "recognition_signals": ["\"Top K\", \"K largest\", \"K smallest\"", "\"K-th element in stream\"", "\"Merge K sorted...\"", "Scheduling with priorities", "Closest K points / K nearest neighbors", "Intuition & Mental Model"], "practice_strategy": "Week 1: LeetCode #703, #1046 — build heap intuition Week 2: K Closest, Top K Frequent, Merge K Sorted Lists — core patterns Week 3: Two-heap median, IPO — advanced combos Always practice both heap and sort approaches, then explain trade-offs", "code_template": "def top_k_largest(nums, k):", "problems": ["LC703", "LC1046", "LC973", "LC347", "LC215", "LC621", "LC23", "LC295", "LC767", "LC632", "LC253", "LC502"], "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m7$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000009'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Linked List',
        content = 'Pattern 8/20 — Linked List. When to use: Cycle detection in linked list Finding the middle node Reversing a list or sublist Merging two sorted lists Removing N-th node from end. Practice: Draw every problem on paper before writing code — non-negotiable for linked lists Master the 5 pointer variables: prev, curr, nxt, dummy, fast, slow Solve Reverse Linked List both . Target 10+ LeetCode problems; recognize pattern in <60s.',
        metadata = metadata || $m8${"track": "dsa", "pattern_order": 8, "pattern_slug": "linked-list", "when_to_use": "Cycle detection in linked list Finding the middle node Reversing a list or sublist Merging two sorted lists Removing N-th node from end", "recognition_signals": ["ListNode input with .next pointer", "\"Reverse\", \"cycle\", \"middle\", \"merge\"", "In-place modification required", "No extra memory allowed", "Intuition & Mental Model", "Linked list problems are pure pointer juggling. The dummy head trick eliminates edge cases for empty lists. Fast/slow pointers are like two runners on a circular track — if there's a loop, the fast one laps the slow one."], "practice_strategy": "Draw every problem on paper before writing code — non-negotiable for linked lists Master the 5 pointer variables: prev, curr, nxt, dummy, fast, slow Solve Reverse Linked List both iteratively AND recursively LRU Cache is a must — it's asked at every major company", "code_template": "def reverse(head):\ndef has_cycle(head):\ndef merge(l1, l2):", "problems": ["LC206", "LC21", "LC141", "LC876", "LC19", "LC142", "LC143", "LC146", "LC138", "LC23", "LC25", "LC430"], "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m8$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000010'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Tree DFS & BFS',
        content = 'Pattern 9/20 — Tree DFS & BFS. When to use: DFS: path sum, max depth, diameter, subtree comparison BFS: level-order traversal, right side view, zigzag order DFS: validate BST, check symmetry BFS: minimum depth, connect level nodes. Practice: Write DFS recursively first, then convert to iterative stack version Practice BFS template until you write it in < 3 minutes from memory Binary Tree Maximum Path Sum is the hardest. Target 10+ LeetCode problems; recognize pattern in <60s.',
        metadata = metadata || $m9${"track": "dsa", "pattern_order": 9, "pattern_slug": "tree-dfs-bfs", "when_to_use": "DFS: path sum, max depth, diameter, subtree comparison BFS: level-order traversal, right side view, zigzag order DFS: validate BST, check symmetry BFS: minimum depth, connect level nodes", "recognition_signals": ["Binary tree input", "\"Level by level\", \"right side view\"", "\"Max depth\", \"path sum\", \"diameter\"", "Serialize/deserialize tree", "\"Lowest common ancestor\"", "Intuition & Mental Model"], "practice_strategy": "Write DFS recursively first, then convert to iterative stack version Practice BFS template until you write it in < 3 minutes from memory Binary Tree Maximum Path Sum is the hardest — solve it last After each problem, identify: was it top-down or bottom-up? Why?", "code_template": "def max_depth(root):\ndef level_order(root):\n    return result", "problems": ["LC104", "LC226", "LC101", "LC102", "LC113", "LC199", "LC235", "LC124", "LC297", "LC543", "LC105", "LC114"], "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m9$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000011'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Tree BFS',
        content = 'Pattern 10/20 — Tree BFS. Level-order queue traversal for right-side views, minimum depth, zigzag order. Target 10+ LeetCode problems.',
        metadata = metadata || $m10${"track": "dsa", "pattern_order": 10, "pattern_slug": "tree-bfs", "when_to_use": "Level-order queue traversal for right-side views, minimum depth, zigzag order.", "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m10$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000012'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Binary Search Tree',
        content = 'Pattern 11/20 — Binary Search Tree. Validate, insert, delete, and in-order properties for efficient tree operations. Target 10+ LeetCode problems.',
        metadata = metadata || $m11${"track": "dsa", "pattern_order": 11, "pattern_slug": "binary-search-tree", "when_to_use": "Validate, insert, delete, and in-order properties for efficient tree operations.", "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m11$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000013'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Binary Search on Answer',
        content = 'Pattern 12/20 — Binary Search on Answer. Search answer space when feasibility predicate is monotonic. Target 10+ LeetCode problems.',
        metadata = metadata || $m12${"track": "dsa", "pattern_order": 12, "pattern_slug": "binary-search-on-answer", "when_to_use": "Search answer space when feasibility predicate is monotonic.", "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m12$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000014'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Graph DFS & BFS',
        content = 'Pattern 13/20 — Graph DFS & BFS. Connected components, islands, flood fill, unweighted shortest paths. Target 10+ LeetCode problems.',
        metadata = metadata || $m13${"track": "dsa", "pattern_order": 13, "pattern_slug": "graph-dfs-bfs", "when_to_use": "Connected components, islands, flood fill, unweighted shortest paths.", "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m13$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000015'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Topological Sort',
        content = 'Pattern 14/20 — Topological Sort. Kahn''s algorithm or DFS post-order for DAG ordering. Target 10+ LeetCode problems.',
        metadata = metadata || $m14${"track": "dsa", "pattern_order": 14, "pattern_slug": "topological-sort", "when_to_use": "Kahn's algorithm or DFS post-order for DAG ordering.", "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m14$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000016'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Union Find (DSU)',
        content = 'Pattern 15/20 — Union Find (DSU). Path compression and rank for dynamic connectivity. Target 10+ LeetCode problems.',
        metadata = metadata || $m15${"track": "dsa", "pattern_order": 15, "pattern_slug": "union-find-dsu", "when_to_use": "Path compression and rank for dynamic connectivity.", "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m15$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000017'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Shortest Path',
        content = 'Pattern 16/20 — Shortest Path. Dijkstra, Bellman-Ford, BFS on weighted/unweighted graphs. Target 10+ LeetCode problems.',
        metadata = metadata || $m16${"track": "dsa", "pattern_order": 16, "pattern_slug": "shortest-path", "when_to_use": "Dijkstra, Bellman-Ford, BFS on weighted/unweighted graphs.", "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m16$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000018'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Dynamic Programming',
        content = 'Pattern 17/20 — Dynamic Programming. 1D, 2D, interval, tree DP, knapsack state transitions. Target 10+ LeetCode problems.',
        metadata = metadata || $m17${"track": "dsa", "pattern_order": 17, "pattern_slug": "dynamic-programming", "when_to_use": "1D, 2D, interval, tree DP, knapsack state transitions.", "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m17$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000019'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Backtracking',
        content = 'Pattern 18/20 — Backtracking. Permutations, combinations, N-Queens, constraint satisfaction. Target 10+ LeetCode problems.',
        metadata = metadata || $m18${"track": "dsa", "pattern_order": 18, "pattern_slug": "backtracking", "when_to_use": "Permutations, combinations, N-Queens, constraint satisfaction.", "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m18$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000020'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Greedy',
        content = 'Pattern 19/20 — Greedy. Activity selection, interval scheduling, locally optimal proofs. Target 10+ LeetCode problems.',
        metadata = metadata || $m19${"track": "dsa", "pattern_order": 19, "pattern_slug": "greedy", "when_to_use": "Activity selection, interval scheduling, locally optimal proofs.", "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m19$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000021'::uuid AND user_id = admin_id;

    UPDATE entities SET
        title = 'Trie',
        content = 'Pattern 20/20 — Trie. Prefix matching, autocomplete, word search, IP routing. Target 10+ LeetCode problems.',
        metadata = metadata || $m20${"track": "dsa", "pattern_order": 20, "pattern_slug": "trie", "when_to_use": "Prefix matching, autocomplete, word search, IP routing.", "benchmark_easy_min": 8, "benchmark_medium_min": 20, "benchmark_hard_min": 35, "source_doc": "dsa_mastery_system.docx"}$m20$::jsonb,
        updated_at = NOW()
    WHERE id = 'c000000c-0001-4001-8001-000000000022'::uuid AND user_id = admin_id;

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES ('c000000c-0001-4001-8001-000000000001'::uuid, admin_id, 'learning_course', 'DSA Mastery System',
     '10-week Mid→Senior curriculum from dsa_mastery_system.docx: 20 patterns, 150–200 problems, daily learn/practice/review/mock cycles, STAR mock interviews, and week-by-week benchmarks.', '["dsa"]'::jsonb, 'learning_seed', $g0${"track": "dsa", "weeks": 10, "target_problems": 200, "program_version": 2}$g0$::jsonb, 'learning', 'active')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content,
        metadata = entities.metadata || EXCLUDED.metadata, updated_at = NOW();

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES ('c000000c-0001-4001-8001-000000000002'::uuid, admin_id, 'learning_topic', '10-Week DSA Roadmap',
     'Phase 1 (W1–2): Two Ptr, HashMap, Prefix, Sliding, BS — 3–4 problems/day. Phase 2 (W3–5): Stack, Heap, Lists, Trees, Graph basics — 4–5/day. Phase 3 (W6–8): Topo, DSU, Dijkstra, DP, Backtrack, Greedy, Trie — morning+evening. Phase 4 (W9–10): timed pairs + full mocks.', '["dsa"]'::jsonb, 'learning_seed', $g1${"track": "dsa", "phase": "roadmap", "weeks": "1-10", "program_version": 2}$g1$::jsonb, 'learning', 'active')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content,
        metadata = entities.metadata || EXCLUDED.metadata, updated_at = NOW();

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES ('c000000c-0001-4001-8001-000000000030'::uuid, admin_id, 'learning_topic', 'DSA Mock Interview (STAR)',
     'UNDERSTAND 2–3m → EXAMPLES 2m → APPROACH 3–5m → CODE 15–20m → TEST 3–5m → COMPLEXITY 1m. Timed: 45min/2 problems or 90min/3. No hints. Talk aloud.', '["dsa"]'::jsonb, 'learning_seed', $g2${"track": "dsa", "phase": "mock", "kind": "mock_framework"}$g2$::jsonb, 'learning', 'active')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content,
        metadata = entities.metadata || EXCLUDED.metadata, updated_at = NOW();

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status)
    VALUES ('c000000c-0001-4001-8001-000000000031'::uuid, admin_id, 'learning_topic', 'DSA Progress Benchmarks',
     'W2: Easy <10min, recognize Two Ptr/Sliding <2min. W5: Medium <25min, 80+ problems. W8: Hard <40min, 130+ problems. W10: 2 Medium in 45min, 160–200 total, 7/10 mock pass rate.', '["dsa"]'::jsonb, 'learning_seed', $g3${"track": "dsa", "phase": "metrics", "kind": "benchmarks"}$g3$::jsonb, 'learning', 'active')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, content = EXCLUDED.content,
        metadata = entities.metadata || EXCLUDED.metadata, updated_at = NOW();

    RAISE NOTICE 'DSA mastery daily program applied for %', owner_email;
END $$;
