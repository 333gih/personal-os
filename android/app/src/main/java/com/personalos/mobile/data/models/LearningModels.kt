package com.personalos.mobile.data.models

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class PosLearningAddResult(
    @Json(name = "entity_id") val entityId: String,
    val type: String,
    val title: String,
    val content: String = "",
)

@JsonClass(generateAdapter = true)
data class PosLearningCoachResult(
    val summary: String = "",
    @Json(name = "practice_questions") val practiceQuestions: List<String> = emptyList(),
    val tips: List<String> = emptyList(),
    @Json(name = "next_steps") val nextSteps: List<String> = emptyList(),
)

@JsonClass(generateAdapter = true)
data class PosInterviewDrillResult(
    @Json(name = "warmup_questions") val warmupQuestions: List<String> = emptyList(),
    @Json(name = "deep_questions") val deepQuestions: List<String> = emptyList(),
    @Json(name = "model_answers_outline") val modelAnswersOutline: List<String> = emptyList(),
    @Json(name = "follow_up_probes") val followUpProbes: List<String> = emptyList(),
    @Json(name = "study_links") val studyLinks: List<String> = emptyList(),
)

@JsonClass(generateAdapter = true)
data class PosLearningSchedule(
    @Json(name = "work_start_hour") val workStartHour: Int = 8,
    @Json(name = "work_end_hour") val workEndHour: Int = 17,
    @Json(name = "work_days") val workDays: List<Int> = listOf(1, 2, 3, 4, 5),
    @Json(name = "commute_minutes") val commuteMinutes: Int = 40,
    @Json(name = "morning_commute_time") val morningCommuteTime: String = "07:15",
    @Json(name = "evening_commute_time") val eveningCommuteTime: String = "17:30",
    @Json(name = "toeic_session_time") val toeicSessionTime: String = "20:00",
    @Json(name = "dsa_commute_minutes") val dsaCommuteMinutes: Int = 25,
    @Json(name = "english_commute_minutes") val englishCommuteMinutes: Int = 20,
    @Json(name = "toeic_daily_minutes") val toeicDailyMinutes: Int = 60,
    val timezone: String = "Asia/Ho_Chi_Minh",
    @Json(name = "push_enabled") val pushEnabled: Boolean = true,
)

@JsonClass(generateAdapter = true)
data class PosTodayStudyBlock(
    val id: String,
    val kind: String,
    val track: String,
    val title: String,
    val subtitle: String = "",
    @Json(name = "start_at") val startAt: String? = null,
    @Json(name = "duration_minutes") val durationMinutes: Int = 0,
    val mode: String = "",
    @Json(name = "entity_id") val entityId: String? = null,
    @Json(name = "commute_tip") val commuteTip: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosDsaBenchmarks(
    @Json(name = "easy_minutes") val easyMinutes: Int = 8,
    @Json(name = "medium_minutes") val mediumMinutes: Int = 20,
    @Json(name = "hard_minutes") val hardMinutes: Int = 35,
)

@JsonClass(generateAdapter = true)
data class PosDsaDailyFocus(
    @Json(name = "program_week") val programWeek: Int = 0,
    @Json(name = "program_day") val programDay: Int = 0,
    val weekday: Int = 0,
    val phase: String = "",
    @Json(name = "day_type") val dayType: String = "",
    @Json(name = "pattern_order") val patternOrder: Int = 0,
    @Json(name = "pattern_title") val patternTitle: String = "",
    @Json(name = "pattern_entity_id") val patternEntityId: String? = null,
    val tasks: List<String> = emptyList(),
    @Json(name = "target_problems") val targetProblems: Int = 0,
    @Json(name = "cumulative_target") val cumulativeTarget: Int = 0,
    @Json(name = "suggested_problems") val suggestedProblems: List<String>? = null,
    @Json(name = "mock_today") val mockToday: Boolean = false,
)

@JsonClass(generateAdapter = true)
data class PosTodayStudyPlan(
    val date: String = "",
    val timezone: String = "",
    @Json(name = "is_work_day") val isWorkDay: Boolean = true,
    val blocks: List<PosTodayStudyBlock> = emptyList(),
    @Json(name = "total_minutes") val totalMinutes: Int = 0,
    val dsa: PosDsaDailyFocus? = null,
)

@JsonClass(generateAdapter = true)
data class PosLearningLessonModule(
    val id: String,
    val title: String,
    val subtitle: String? = null,
    @Json(name = "pattern_order") val patternOrder: Int = 0,
    val phase: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosPracticeMode(
    val id: String,
    val title: String,
    val subtitle: String = "",
    @Json(name = "duration_minutes") val durationMinutes: Int = 5,
    val focus: String = "",
    @Json(name = "async") val isAsync: Boolean = false,
)

@JsonClass(generateAdapter = true)
data class PosLearningLesson(
    @Json(name = "entity_id") val entityId: String,
    val title: String,
    val content: String = "",
    val type: String = "",
    val track: String = "",
    val phase: String? = null,
    val weeks: String? = null,
    @Json(name = "pattern_order") val patternOrder: Int = 0,
    @Json(name = "when_to_use") val whenToUse: String? = null,
    @Json(name = "recognition_signals") val recognitionSignals: List<String> = emptyList(),
    @Json(name = "practice_strategy") val practiceStrategy: String? = null,
    @Json(name = "code_template") val codeTemplate: String? = null,
    val problems: List<String> = emptyList(),
    val benchmarks: PosDsaBenchmarks? = null,
    val modules: List<PosLearningLessonModule> = emptyList(),
    @Json(name = "practice_modes") val practiceModes: List<PosPracticeMode> = emptyList(),
    @Json(name = "curriculum_week") val curriculumWeek: Int = 0,
)

@JsonClass(generateAdapter = true)
data class PosStudyJob(
    val id: String,
    val status: String,
    @Json(name = "error_message") val errorMessage: String? = null,
    val result: PosLearningCoachResult? = null,
)

@JsonClass(generateAdapter = true)
data class PosNotificationLogItem(
    val id: String,
    val channel: String = "",
    val title: String,
    val body: String = "",
    val status: String = "",
    @Json(name = "created_at") val createdAt: String = "",
    @Json(name = "error_message") val errorMessage: String? = null,
)

@JsonClass(generateAdapter = true)
data class PosNotificationLogResponse(val items: List<PosNotificationLogItem> = emptyList())
