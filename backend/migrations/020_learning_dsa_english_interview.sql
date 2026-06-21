-- Learning (DSA + English) and interview prep seed for mphuc8671@gmail.com
-- psql $DATABASE_URL -f migrations/020_learning_dsa_english_interview.sql

DO $$
DECLARE
    admin_id UUID;
    owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE NOTICE 'Owner % not found — skip learning/interview seed', owner_email;
        RETURN;
    END IF;

    DELETE FROM entities
    WHERE user_id = admin_id AND source IN ('learning_seed', 'interview_seed');

    INSERT INTO entities (id, user_id, type, title, content, tags, source, metadata, domain, status) VALUES

    -- DSA Mastery course
    ('c000000c-0001-4001-8001-000000000001'::uuid, admin_id, 'learning_course', 'DSA Mastery System',
     'Mid-level to senior interview curriculum: 20 core patterns, 150+ problems, and a structured 10-week roadmap with code templates and timed mock practice.',
     '["dsa","mastery"]'::jsonb, 'learning_seed',
     '{"track":"dsa","weeks":10,"target_problems":150}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000002'::uuid, admin_id, 'learning_topic', '10-Week DSA Roadmap',
     'Study patterns in difficulty order: foundation (weeks 1–2), intermediate (3–5), advanced (6–8), expert (8–10). Daily mix of learn, medium practice, review, and timed mocks.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","phase":"roadmap","weeks":"1-10"}'::jsonb,
     'learning', 'active'),

    -- DSA pattern topics (20)
    ('c000000c-0001-4001-8001-000000000003'::uuid, admin_id, 'learning_topic', 'Two Pointers',
     'Use two indices on sorted arrays or strings for pair, partition, and in-place problems in O(n) with O(1) extra space. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":1,"phase":"foundation","weeks":"1-2","difficulty":"easy-medium"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000004'::uuid, admin_id, 'learning_topic', 'Sliding Window',
     'Maintain a fixed or variable contiguous window with two pointers; expand and shrink based on constraints for subarray/substring problems. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":2,"phase":"foundation","weeks":"1-2","difficulty":"easy-medium"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000005'::uuid, admin_id, 'learning_topic', 'HashMap / Frequency Counting',
     'Trade O(n) space for O(1) lookups: complements, frequencies, anagrams, and grouping by property in a single pass. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":3,"phase":"foundation","weeks":"1-2","difficulty":"easy-medium"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000006'::uuid, admin_id, 'learning_topic', 'Prefix Sum',
     'Precompute cumulative sums for O(1) range queries; combine with hashmaps for subarray-sum and modulo problems. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":4,"phase":"foundation","weeks":"1-2","difficulty":"easy-medium"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000007'::uuid, admin_id, 'learning_topic', 'Binary Search',
     'Halve search space on sorted data or monotonic predicates; find exact values, boundaries, or optimal parameters in O(log n). Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":5,"phase":"foundation","weeks":"1-2","difficulty":"easy-medium"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000008'::uuid, admin_id, 'learning_topic', 'Stack & Monotonic Stack',
     'LIFO stacks for brackets and expressions; monotonic stacks for next greater/smaller and histogram area in linear time. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":6,"phase":"intermediate","weeks":"3-5","difficulty":"medium"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000009'::uuid, admin_id, 'learning_topic', 'Heap / Priority Queue',
     'Min/max heaps for top-K, K-way merge, scheduling, and streaming median without sorting the full dataset. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":7,"phase":"intermediate","weeks":"3-5","difficulty":"medium"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000010'::uuid, admin_id, 'learning_topic', 'Linked List',
     'Pointer manipulation: dummy heads, in-place reversal, fast/slow cycle detection, merge, and LRU-style designs. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":8,"phase":"intermediate","weeks":"3-5","difficulty":"medium"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000011'::uuid, admin_id, 'learning_topic', 'Tree DFS',
     'Depth-first recursion or stack for path sums, depth, diameter, serialization, and bottom-up subtree aggregation. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":9,"phase":"intermediate","weeks":"3-5","difficulty":"medium"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000012'::uuid, admin_id, 'learning_topic', 'Tree BFS',
     'Level-order queue traversal for right-side views, minimum depth, zigzag order, and shortest paths in unweighted trees. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":10,"phase":"intermediate","weeks":"3-5","difficulty":"medium"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000013'::uuid, admin_id, 'learning_topic', 'Binary Search Tree',
     'Leverage ordering: validate, search, insert, delete, and in-order properties for efficient tree operations. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":11,"phase":"intermediate","weeks":"3-5","difficulty":"medium"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000014'::uuid, admin_id, 'learning_topic', 'Binary Search on Answer',
     'Search the answer space (not the array) when a feasibility predicate is monotonic — minimize maximum or maximize minimum. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":12,"phase":"intermediate","weeks":"3-5","difficulty":"medium-hard"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000015'::uuid, admin_id, 'learning_topic', 'Graph DFS & BFS',
     'Traverse adjacency lists for connected components, islands, flood fill, and unweighted shortest paths. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":13,"phase":"advanced","weeks":"6-8","difficulty":"medium-hard"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000016'::uuid, admin_id, 'learning_topic', 'Topological Sort',
     'Order nodes in DAGs via Kahn''s algorithm or DFS post-order for course schedules and dependency resolution. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":14,"phase":"advanced","weeks":"6-8","difficulty":"medium-hard"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000017'::uuid, admin_id, 'learning_topic', 'Union Find (DSU)',
     'Disjoint-set union with path compression and rank for dynamic connectivity, components, and cycle detection. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":15,"phase":"advanced","weeks":"6-8","difficulty":"medium-hard"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000018'::uuid, admin_id, 'learning_topic', 'Shortest Path',
     'Dijkstra, Bellman-Ford, and BFS on weighted or unweighted graphs for single-source and grid shortest paths. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":16,"phase":"advanced","weeks":"6-8","difficulty":"hard"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000019'::uuid, admin_id, 'learning_topic', 'Dynamic Programming',
     'Break problems into overlapping subproblems: 1D, 2D, interval, tree, and knapsack-style state transitions. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":17,"phase":"advanced","weeks":"6-8","difficulty":"hard"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000020'::uuid, admin_id, 'learning_topic', 'Backtracking',
     'Explore decision trees with prune-on-fail: permutations, combinations, subsets, N-Queens, and constraint satisfaction. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":18,"phase":"advanced","weeks":"6-8","difficulty":"hard"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000021'::uuid, admin_id, 'learning_topic', 'Greedy',
     'Locally optimal choices with proof of global optimum: intervals, activity selection, and scheduling problems. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":19,"phase":"expert","weeks":"8-10","difficulty":"medium-hard"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000022'::uuid, admin_id, 'learning_topic', 'Trie',
     'Prefix trees for autocomplete, word search, IP routing, and efficient string prefix matching. Target: 10+ LeetCode problems.',
     '["dsa"]'::jsonb, 'learning_seed',
     '{"track":"dsa","pattern_order":20,"phase":"expert","weeks":"8-10","difficulty":"medium-hard"}'::jsonb,
     'learning', 'active'),

    -- English courses (5)
    ('c000000c-0001-4001-8001-000000000023'::uuid, admin_id, 'learning_course', 'English Grammar & Vocabulary Foundation',
     'Build accurate sentence structure, core grammar rules, and high-frequency vocabulary for professional and technical communication.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"english-grammar-vocabulary-foundation","level":"beginner"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000024'::uuid, admin_id, 'learning_course', 'Technical Interview English',
     'Communicate solutions clearly in coding and system-design interviews: structure, terminology, and confident follow-ups.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"technical-interview-english","level":"intermediate"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000025'::uuid, admin_id, 'learning_course', 'Business & Workplace Communication',
     'Professional email, meetings, presentations, and feedback language for distributed and cross-cultural teams.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"business-workplace-communication","level":"intermediate"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000026'::uuid, admin_id, 'learning_course', 'Reading, Writing & IELTS Prep',
     'Reading strategies, structured writing, and targeted IELTS Task 1 and Task 2 practice with timed drills.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"reading-writing-ielts-prep","level":"intermediate-advanced"}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000027'::uuid, admin_id, 'learning_course', 'Speaking, Listening & Pronunciation Lab',
     'Pronunciation, active listening, fluency drills, and spoken practice for interviews and daily workplace use.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"speaking-listening-pronunciation-lab","level":"intermediate"}'::jsonb,
     'learning', 'active'),

    -- English Grammar & Vocabulary Foundation modules
    ('c000000c-0001-4001-8001-000000000028'::uuid, admin_id, 'learning_topic', 'Parts of Speech & Sentence Structure',
     'Nouns, verbs, adjectives, and adverbs; subject–verb–object order and common sentence patterns in formal English.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"english-grammar-vocabulary-foundation","module_order":1}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000029'::uuid, admin_id, 'learning_topic', 'Tenses & Subject–Verb Agreement',
     'Present, past, and future forms; continuous and perfect aspects; agreement with singular/plural and collective nouns.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"english-grammar-vocabulary-foundation","module_order":2}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000030'::uuid, admin_id, 'learning_topic', 'Core Vocabulary Building',
     'High-frequency academic and workplace word lists, collocations, and context-based retention techniques.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"english-grammar-vocabulary-foundation","module_order":3}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000031'::uuid, admin_id, 'learning_topic', 'Common Grammar Errors & Fixes',
     'Articles, prepositions, double negatives, and word-choice mistakes common among non-native speakers.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"english-grammar-vocabulary-foundation","module_order":4}'::jsonb,
     'learning', 'active'),

    -- Technical Interview English modules
    ('c000000c-0001-4001-8001-000000000032'::uuid, admin_id, 'learning_topic', 'Explaining Your Approach Clearly',
     'Restate the problem, walk through examples, and narrate brute force before optimization — the interview communication baseline.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"technical-interview-english","module_order":1}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000033'::uuid, admin_id, 'learning_topic', 'Technical Terminology & Idioms',
     'Precise vocabulary for algorithms, system design, trade-offs, latency, throughput, and scalability discussions.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"technical-interview-english","module_order":2}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000034'::uuid, admin_id, 'learning_topic', 'Mock Q&A Framework (STAR / PEEL)',
     'Structured answers for behavioral and technical follow-ups using Situation–Task–Action–Result and Point–Evidence–Explanation.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"technical-interview-english","module_order":3}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000035'::uuid, admin_id, 'learning_topic', 'Handling Follow-up Questions',
     'Clarifying assumptions, discussing edge cases, and pivoting when the interviewer probes complexity or design choices.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"technical-interview-english","module_order":4}'::jsonb,
     'learning', 'active'),

    -- Business & Workplace Communication modules
    ('c000000c-0001-4001-8001-000000000036'::uuid, admin_id, 'learning_topic', 'Email & Async Messaging',
     'Concise subject lines, action-oriented requests, and professional tone in email and Slack/Teams.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"business-workplace-communication","module_order":1}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000037'::uuid, admin_id, 'learning_topic', 'Meetings & Presentations',
     'Agenda setting, summarizing decisions, and delivering status updates and technical demos with clarity.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"business-workplace-communication","module_order":2}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000038'::uuid, admin_id, 'learning_topic', 'Negotiation & Feedback Language',
     'Polite disagreement, constructive feedback, and framing proposals for stakeholders and peers.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"business-workplace-communication","module_order":3}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000039'::uuid, admin_id, 'learning_topic', 'Cross-cultural Professional Tone',
     'Direct vs indirect communication, formality levels, and inclusive language in global teams.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"business-workplace-communication","module_order":4}'::jsonb,
     'learning', 'active'),

    -- Reading, Writing & IELTS Prep modules
    ('c000000c-0001-4001-8001-000000000040'::uuid, admin_id, 'learning_topic', 'Skimming & Scanning Strategies',
     'Speed-reading techniques for gist, detail location, and inference under time pressure.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"reading-writing-ielts-prep","module_order":1}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000041'::uuid, admin_id, 'learning_topic', 'Academic & Essay Writing Structure',
     'Introduction, thesis, body paragraphs with evidence, and conclusions for formal writing tasks.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"reading-writing-ielts-prep","module_order":2}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000042'::uuid, admin_id, 'learning_topic', 'IELTS Task 1 (Charts & Letters)',
     'Describe trends, compare data, and write formal/semi-formal letters within word and time limits.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"reading-writing-ielts-prep","module_order":3}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000043'::uuid, admin_id, 'learning_topic', 'IELTS Task 2 (Argument Essays)',
     'Opinion, discussion, and problem–solution essays with coherent argumentation and lexical range.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"reading-writing-ielts-prep","module_order":4}'::jsonb,
     'learning', 'active'),

    -- Speaking, Listening & Pronunciation Lab modules
    ('c000000c-0001-4001-8001-000000000044'::uuid, admin_id, 'learning_topic', 'Pronunciation & Word Stress',
     'Vowel/consonant clarity, sentence stress, and intonation patterns for clearer spoken English.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"speaking-listening-pronunciation-lab","module_order":1}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000045'::uuid, admin_id, 'learning_topic', 'Active Listening Techniques',
     'Note-taking, paraphrasing, and confirming understanding in meetings and one-on-one conversations.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"speaking-listening-pronunciation-lab","module_order":2}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000046'::uuid, admin_id, 'learning_topic', 'Fluency Drills & Shadowing',
     'Timed speaking prompts, shadowing native audio, and reducing hesitation in spontaneous speech.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"speaking-listening-pronunciation-lab","module_order":3}'::jsonb,
     'learning', 'active'),

    ('c000000c-0001-4001-8001-000000000047'::uuid, admin_id, 'learning_topic', 'Interview & Panel Speaking Practice',
     'Mock introductions, project walkthroughs, and Q&A under timed conditions with self-review rubrics.',
     '["english"]'::jsonb, 'learning_seed',
     '{"track":"english","course_slug":"speaking-listening-pronunciation-lab","module_order":4}'::jsonb,
     'learning', 'active'),

    -- Interview prep (work domain, 9 topics)
    ('c000000d-0001-4001-8001-000000000001'::uuid, admin_id, 'work_interview_topic', 'Design Patterns',
     'Creational, structural, and behavioral patterns: Singleton, Factory, Observer, Strategy, and when to apply each in production code.',
     '["interview"]'::jsonb, 'interview_seed',
     '{"reference_urls":["https://www.geeksforgeeks.org/design-patterns-set-1-introduction/","https://www.geeksforgeeks.org/design-patterns-set-2-factory/"]}'::jsonb,
     'work', 'active'),

    ('c000000d-0001-4001-8001-000000000002'::uuid, admin_id, 'work_interview_topic', 'Java Concurrency',
     'Threads, executors, synchronized blocks, volatile, concurrent collections, and common pitfalls in multi-threaded Java.',
     '["interview"]'::jsonb, 'interview_seed',
     '{"reference_urls":["https://www.baeldung.com/java-concurrency","https://www.baeldung.com/java-thread-pool"]}'::jsonb,
     'work', 'active'),

    ('c000000d-0001-4001-8001-000000000003'::uuid, admin_id, 'work_interview_topic', 'Spring Security',
     'Authentication vs authorization, filter chain, JWT/OAuth2 basics, method security, and securing REST APIs.',
     '["interview"]'::jsonb, 'interview_seed',
     '{"reference_urls":["https://www.geeksforgeeks.org/spring-security/","https://www.geeksforgeeks.org/spring-security-architecture/"]}'::jsonb,
     'work', 'active'),

    ('c000000d-0001-4001-8001-000000000004'::uuid, admin_id, 'work_interview_topic', 'Spring AOP',
     'Aspects, join points, advice types (before/after/around), pointcut expressions, and cross-cutting concerns like logging and transactions.',
     '["interview"]'::jsonb, 'interview_seed',
     '{"reference_urls":["https://www.geeksforgeeks.org/spring-aop/","https://www.baeldung.com/spring-aop"]}'::jsonb,
     'work', 'active'),

    ('c000000d-0001-4001-8001-000000000005'::uuid, admin_id, 'work_interview_topic', 'Cache & System Design',
     'Cache-aside, write-through, TTL/eviction, cache stampede, and designing scalable read-heavy systems with Redis or in-memory layers.',
     '["interview"]'::jsonb, 'interview_seed',
     '{"reference_urls":["https://www.geeksforgeeks.org/caching-system-design/","https://www.ambitionbox.com/interviews/caching-system-design-interview-questions"]}'::jsonb,
     'work', 'active'),

    ('c000000d-0001-4001-8001-000000000006'::uuid, admin_id, 'work_interview_topic', 'PostgreSQL',
     'Indexing, query plans, transactions, isolation levels, normalization, and performance tuning for relational workloads.',
     '["interview"]'::jsonb, 'interview_seed',
     '{"reference_urls":["https://www.geeksforgeeks.org/postgresql-interview-questions/"]}'::jsonb,
     'work', 'active'),

    ('c000000d-0001-4001-8001-000000000007'::uuid, admin_id, 'work_interview_topic', 'MongoDB',
     'Document model, sharding, replication, aggregation pipeline, indexing strategies, and consistency trade-offs.',
     '["interview"]'::jsonb, 'interview_seed',
     '{"reference_urls":["https://www.geeksforgeeks.org/mongodb-interview-questions/"]}'::jsonb,
     'work', 'active'),

    ('c000000d-0001-4001-8001-000000000008'::uuid, admin_id, 'work_interview_topic', 'SQL',
     'Joins, subqueries, window functions, GROUP BY/HAVING, indexing implications, and query optimization fundamentals.',
     '["interview"]'::jsonb, 'interview_seed',
     '{"reference_urls":["https://www.geeksforgeeks.org/sql-interview-questions/"]}'::jsonb,
     'work', 'active'),

    ('c000000d-0001-4001-8001-000000000009'::uuid, admin_id, 'work_interview_topic', 'Kafka',
     'Topics, partitions, consumer groups, delivery semantics, rebalancing, and production deployment strategies for event streaming.',
     '["interview"]'::jsonb, 'interview_seed',
     '{"reference_urls":["https://www.kai-waehner.de/blog/2020/05/09/apache-kafka-apache-parallel-deployment-strategies/"]}'::jsonb,
     'work', 'active');

    RAISE NOTICE 'Learning and interview seed applied for %', owner_email;
END $$;
