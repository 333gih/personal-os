package com.personalos.mobile.data.repository

import com.personalos.mobile.data.models.PosAssembledCv
import com.personalos.mobile.data.models.PosCvAddBlockFromEntityRequest
import com.personalos.mobile.data.models.PosCvAddSkillRequest
import com.personalos.mobile.data.models.PosCvAddSkillResponse
import com.personalos.mobile.data.models.PosCvBlockOverrides
import com.personalos.mobile.data.models.PosCvCreateTemplateRequest
import com.personalos.mobile.data.models.PosCvDocument
import com.personalos.mobile.data.models.PosCvLayoutsResponse
import com.personalos.mobile.data.models.PosCvRefineBlockRequest
import com.personalos.mobile.data.models.PosCvRefineRequest
import com.personalos.mobile.data.models.PosCvRefineResponse
import com.personalos.mobile.data.models.PosCvSaveRequest
import com.personalos.mobile.data.models.PosCvSaveTemplateRequest
import com.personalos.mobile.data.models.PosCvShareResponse
import com.personalos.mobile.data.models.PosCvSuggestSkillsResponse
import com.personalos.mobile.data.models.PosCvTemplate
import com.personalos.mobile.data.models.PosCvTemplatesResponse
import com.personalos.mobile.data.models.PosCvValidateRequest
import com.personalos.mobile.data.models.PosCvValidateResult
import com.personalos.mobile.data.models.PosDashboard
import com.personalos.mobile.data.models.PosEntityDetailResponse
import com.personalos.mobile.data.models.PosEntityListResponse
import com.personalos.mobile.data.models.PosInterviewDrillResult
import com.personalos.mobile.data.models.PosJobListResponse
import com.personalos.mobile.data.models.PosJobScanResult
import com.personalos.mobile.data.models.PosJobScanStatusResponse
import com.personalos.mobile.data.models.PosJobSearchPreferences
import com.personalos.mobile.data.models.PosJobStatusRequest
import com.personalos.mobile.data.models.PosLearningAddResult
import com.personalos.mobile.data.models.PosLearningCoachResult
import com.personalos.mobile.data.models.PosLearningLesson
import com.personalos.mobile.data.models.PosLearningSchedule
import com.personalos.mobile.data.models.PosNotificationLogResponse
import com.personalos.mobile.data.models.PosSearchResponse
import com.personalos.mobile.data.models.PosStartupAddResult
import com.personalos.mobile.data.models.PosStudyJob
import com.personalos.mobile.data.models.PosTodayStudyPlan
import com.personalos.mobile.data.models.PosUser
import com.personalos.mobile.data.models.PosWorkAddResult
import com.personalos.mobile.data.models.PosWorkImportResult
import com.personalos.mobile.network.MobileApiClient
import com.squareup.moshi.Moshi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.File

class PersonalOSRepository(
    private val api: MobileApiClient,
    moshi: Moshi,
) {
    private val userAdapter = moshi.adapter(PosUser::class.java)
    private val dashboardAdapter = moshi.adapter(PosDashboard::class.java)
    private val entityListAdapter = moshi.adapter(PosEntityListResponse::class.java)
    private val entityDetailAdapter = moshi.adapter(PosEntityDetailResponse::class.java)
    private val searchAdapter = moshi.adapter(PosSearchResponse::class.java)
    private val cvAdapter = moshi.adapter(PosAssembledCv::class.java)
    private val cvSaveAdapter = moshi.adapter(PosCvSaveRequest::class.java)
    private val cvRefineReqAdapter = moshi.adapter(PosCvRefineRequest::class.java)
    private val cvRefineResAdapter = moshi.adapter(PosCvRefineResponse::class.java)
    private val cvShareAdapter = moshi.adapter(PosCvShareResponse::class.java)
    private val cvSuggestAdapter = moshi.adapter(PosCvSuggestSkillsResponse::class.java)
    private val cvAddSkillReqAdapter = moshi.adapter(PosCvAddSkillRequest::class.java)
    private val cvAddSkillResAdapter = moshi.adapter(PosCvAddSkillResponse::class.java)
    private val cvTemplatesAdapter = moshi.adapter(PosCvTemplatesResponse::class.java)
    private val cvTemplateAdapter = moshi.adapter(PosCvTemplate::class.java)
    private val cvLayoutsAdapter = moshi.adapter(PosCvLayoutsResponse::class.java)
    private val cvValidateAdapter = moshi.adapter(PosCvValidateResult::class.java)
    private val cvSaveTemplateAdapter = moshi.adapter(PosCvSaveTemplateRequest::class.java)
    private val cvValidateReqAdapter = moshi.adapter(PosCvValidateRequest::class.java)
    private val cvCreateTemplateAdapter = moshi.adapter(PosCvCreateTemplateRequest::class.java)
    private val cvRefineBlockAdapter = moshi.adapter(PosCvRefineBlockRequest::class.java)
    private val cvAddBlockAdapter = moshi.adapter(PosCvAddBlockFromEntityRequest::class.java)
    private val jobListAdapter = moshi.adapter(PosJobListResponse::class.java)
    private val jobScanStatusAdapter = moshi.adapter(PosJobScanStatusResponse::class.java)
    private val jobPrefsAdapter = moshi.adapter(PosJobSearchPreferences::class.java)
    private val jobStatusAdapter = moshi.adapter(PosJobStatusRequest::class.java)
    private val workAddAdapter = moshi.adapter(PosWorkAddResult::class.java)
    private val startupAddAdapter = moshi.adapter(PosStartupAddResult::class.java)
    private val workImportAdapter = moshi.adapter(PosWorkImportResult::class.java)
    private val learningAddAdapter = moshi.adapter(PosLearningAddResult::class.java)
    private val learningCoachAdapter = moshi.adapter(PosLearningCoachResult::class.java)
    private val learningScheduleAdapter = moshi.adapter(PosLearningSchedule::class.java)
    private val todayPlanAdapter = moshi.adapter(PosTodayStudyPlan::class.java)
    private val lessonAdapter = moshi.adapter(PosLearningLesson::class.java)
    private val notificationLogAdapter = moshi.adapter(PosNotificationLogResponse::class.java)
    private val studyJobAdapter = moshi.adapter(PosStudyJob::class.java)
    private val interviewDrillAdapter = moshi.adapter(PosInterviewDrillResult::class.java)

    suspend fun me(): PosUser = withContext(Dispatchers.IO) {
        decode(api.get("auth/me"), userAdapter)
    }

    suspend fun dashboard(): PosDashboard = withContext(Dispatchers.IO) {
        decode(api.get("dashboard"), dashboardAdapter)
    }

    suspend fun listEntities(domain: String, limit: Int = 120): PosEntityListResponse =
        withContext(Dispatchers.IO) {
            decode(api.get("entities?domain=${encode(domain)}&limit=$limit"), entityListAdapter)
        }

    suspend fun entityDetail(id: String): PosEntityDetailResponse = withContext(Dispatchers.IO) {
        decode(api.get("entities/$id/detail"), entityDetailAdapter)
    }

    suspend fun search(query: String, mode: String = "hybrid"): PosSearchResponse =
        withContext(Dispatchers.IO) {
            val body = JSONObject().put("query", query).put("mode", mode).toString()
            decode(api.post("search", body), searchAdapter)
        }

    suspend fun fetchCv(): PosAssembledCv = withContext(Dispatchers.IO) {
        decode(api.get("cv"), cvAdapter)
    }

    suspend fun saveCv(document: PosCvDocument): PosAssembledCv = withContext(Dispatchers.IO) {
        decode(api.put("cv", cvSaveAdapter.toJson(PosCvSaveRequest(document))), cvAdapter)
    }

    suspend fun refineCv(instruction: String, section: String, content: String): PosCvRefineResponse =
        withContext(Dispatchers.IO) {
            val json = cvRefineReqAdapter.toJson(PosCvRefineRequest(instruction, section, content))
            decode(api.post("cv/refine", json), cvRefineResAdapter)
        }

    suspend fun downloadCvPdf(templateId: String? = null): ByteArray = withContext(Dispatchers.IO) {
        val path = if (templateId.isNullOrBlank()) "cv/export/pdf" else "cv/export/pdf?template_id=${encode(templateId)}"
        api.getBytes(path)
    }

    suspend fun listCvTemplates(): List<PosCvTemplate> = withContext(Dispatchers.IO) {
        decode(api.get("cv/templates"), cvTemplatesAdapter).templates
    }

    suspend fun syncCvSystemTemplates(): List<PosCvTemplate> = withContext(Dispatchers.IO) {
        decode(api.post("cv/templates/sync-system", "{}"), cvTemplatesAdapter).templates
    }

    suspend fun listCvLayouts() = withContext(Dispatchers.IO) {
        decode(api.get("cv/layouts"), cvLayoutsAdapter).layouts
    }

    suspend fun getCvTemplate(id: String): PosCvTemplate = withContext(Dispatchers.IO) {
        decode(api.get("cv/templates/$id"), cvTemplateAdapter)
    }

    suspend fun createCvTemplate(name: String, layoutId: String = "", cloneId: String = ""): PosCvTemplate =
        withContext(Dispatchers.IO) {
            val json = cvCreateTemplateAdapter.toJson(PosCvCreateTemplateRequest(name, layoutId, cloneId))
            decode(api.post("cv/templates", json), cvTemplateAdapter)
        }

    suspend fun saveCvTemplate(template: PosCvTemplate, force: Boolean = false): PosCvTemplate =
        withContext(Dispatchers.IO) {
            val json = cvSaveTemplateAdapter.toJson(PosCvSaveTemplateRequest(template, force))
            decode(api.put("cv/templates/${template.id}", json), cvTemplateAdapter)
        }

    suspend fun validateCvTemplate(templateId: String, template: PosCvTemplate? = null): PosCvValidateResult =
        withContext(Dispatchers.IO) {
            val body = template?.let { cvValidateReqAdapter.toJson(PosCvValidateRequest(it)) } ?: "{}"
            decode(api.post("cv/templates/$templateId/validate", body), cvValidateAdapter)
        }

    suspend fun refineCvBlock(content: String, instruction: String = ""): PosCvRefineResponse =
        withContext(Dispatchers.IO) {
            val json = cvRefineBlockAdapter.toJson(PosCvRefineBlockRequest(instruction, content))
            decode(api.post("cv/templates/0/blocks/0/refine", json), cvRefineResAdapter)
        }

    suspend fun addCvBlockFromEntity(
        templateId: String,
        entityId: String,
        blockType: String,
        overrides: PosCvBlockOverrides? = null,
    ): PosCvTemplate = withContext(Dispatchers.IO) {
        val json = cvAddBlockAdapter.toJson(PosCvAddBlockFromEntityRequest(entityId, blockType, overrides))
        decode(api.post("cv/templates/$templateId/blocks/from-entity", json), cvTemplateAdapter)
    }

    suspend fun shareCv(): PosCvShareResponse = withContext(Dispatchers.IO) {
        decode(api.post("cv/share", "{}"), cvShareAdapter)
    }

    suspend fun suggestCvSkills(): PosCvSuggestSkillsResponse = withContext(Dispatchers.IO) {
        decode(api.post("cv/suggest-skills", "{}"), cvSuggestAdapter)
    }

    suspend fun addCvSkill(category: String, skill: String): PosCvAddSkillResponse =
        withContext(Dispatchers.IO) {
            val json = cvAddSkillReqAdapter.toJson(PosCvAddSkillRequest(category, skill))
            decode(api.post("cv/skills/add", json), cvAddSkillResAdapter)
        }

    suspend fun fetchJobs(status: String): List<com.personalos.mobile.data.models.PosJobOpportunity> =
        withContext(Dispatchers.IO) {
            decode(api.get("jobs?status=${encode(status)}"), jobListAdapter).jobs
        }

    suspend fun scanJobs(): PosJobScanResult = withContext(Dispatchers.IO) {
        api.post("jobs/scan", "{}")
        repeat(90) { attempt ->
            if (attempt > 0) delay(2000)
            val status = decode(api.get("jobs/scan/status"), jobScanStatusAdapter)
            when (status.status) {
                "completed" -> return@withContext status.result ?: PosJobScanResult()
                "failed" -> error(status.error ?: "Job scan failed")
            }
        }
        error("Scan still running — try again shortly.")
    }

    suspend fun updateJobStatus(id: String, status: String) = withContext(Dispatchers.IO) {
        val json = jobStatusAdapter.toJson(PosJobStatusRequest(status))
        ensureOk(api.patch("jobs/$id/status", json))
    }

    suspend fun fetchJobPreferences(): PosJobSearchPreferences = withContext(Dispatchers.IO) {
        decode(api.get("jobs/preferences"), jobPrefsAdapter)
    }

    suspend fun saveJobPreferences(prefs: PosJobSearchPreferences): PosJobSearchPreferences =
        withContext(Dispatchers.IO) {
            decode(api.put("jobs/preferences", jobPrefsAdapter.toJson(prefs)), jobPrefsAdapter)
        }

    suspend fun addWorkEntry(kind: String, rawText: String, titleHint: String = ""): PosWorkAddResult =
        withContext(Dispatchers.IO) {
            val body = JSONObject()
                .put("kind", kind)
                .put("raw_text", rawText)
                .put("title_hint", titleHint)
                .toString()
            decode(api.post("work/add", body), workAddAdapter)
        }

    suspend fun addStartupEntry(kind: String, rawText: String, titleHint: String = ""): PosStartupAddResult =
        withContext(Dispatchers.IO) {
            val body = JSONObject()
                .put("kind", kind)
                .put("raw_text", rawText)
                .put("title_hint", titleHint)
                .toString()
            decode(api.post("startup/add", body), startupAddAdapter)
        }

    suspend fun importWorkProject(
        title: String,
        company: String,
        markdown: String,
        diagramFile: File?,
    ): PosWorkImportResult = withContext(Dispatchers.IO) {
        val boundary = "Boundary-${System.currentTimeMillis()}"
        val multipart = MultipartBody.Builder(boundary)
            .setType(MultipartBody.FORM)
            .addFormDataPart("title", title)
            .addFormDataPart("company", company)
            .addFormDataPart("markdown", markdown)
        diagramFile?.let { file ->
            multipart.addFormDataPart(
                "diagram",
                "diagram.png",
                file.asRequestBody("image/png".toMediaType()),
            )
        }
        val contentType = "multipart/form-data; boundary=$boundary"
        decode(api.postMultipart("work/import", multipart.build(), contentType), workImportAdapter)
    }

    suspend fun addLearningEntry(
        kind: String,
        track: String,
        rawText: String,
        titleHint: String = "",
    ): PosLearningAddResult = withContext(Dispatchers.IO) {
        val body = JSONObject()
            .put("kind", kind)
            .put("track", track)
            .put("raw_text", rawText)
            .put("title_hint", titleHint)
            .toString()
        decode(api.post("learning/add", body), learningAddAdapter)
    }

    suspend fun coachLearning(
        entityId: String?,
        topic: String,
        track: String,
        focus: String,
    ): PosLearningCoachResult = withContext(Dispatchers.IO) {
        val body = JSONObject()
            .put("topic", topic)
            .put("track", track)
            .put("focus", focus)
        entityId?.let { body.put("entity_id", it) }
        decode(api.post("learning/coach", body.toString()), learningCoachAdapter)
    }

    suspend fun coachLearningAsync(
        entityId: String?,
        topic: String,
        track: String,
        focus: String,
    ): PosStudyJob = withContext(Dispatchers.IO) {
        val body = JSONObject()
            .put("topic", topic)
            .put("track", track)
            .put("focus", focus)
        entityId?.let { body.put("entity_id", it) }
        decode(api.post("learning/coach/async", body.toString()), studyJobAdapter)
    }

    suspend fun pollStudyJob(id: String): PosStudyJob = withContext(Dispatchers.IO) {
        repeat(90) { attempt ->
            if (attempt > 0) delay(2000)
            val job = decode(api.get("learning/jobs/$id"), studyJobAdapter)
            when (job.status) {
                "done" -> return@withContext job
                "failed" -> error(job.errorMessage ?: "Coach job failed")
            }
        }
        error("Coach still running")
    }

    suspend fun fetchLearningSchedule(): PosLearningSchedule = withContext(Dispatchers.IO) {
        decode(api.get("learning/schedule"), learningScheduleAdapter)
    }

    suspend fun saveLearningSchedule(schedule: PosLearningSchedule): PosLearningSchedule =
        withContext(Dispatchers.IO) {
            decode(api.put("learning/schedule", learningScheduleAdapter.toJson(schedule)), learningScheduleAdapter)
        }

    suspend fun fetchLearningToday(): PosTodayStudyPlan = withContext(Dispatchers.IO) {
        decode(api.get("learning/today"), todayPlanAdapter)
    }

    suspend fun fetchLearningLesson(id: String): PosLearningLesson = withContext(Dispatchers.IO) {
        decode(api.get("learning/lessons/$id"), lessonAdapter)
    }

    suspend fun fetchNotificationLog(limit: Int = 50): PosNotificationLogResponse =
        withContext(Dispatchers.IO) {
            decode(api.get("learning/notifications/log?limit=$limit"), notificationLogAdapter)
        }

    suspend fun interviewDrill(
        entityId: String?,
        topic: String,
        stack: String,
        level: String,
    ): PosInterviewDrillResult = withContext(Dispatchers.IO) {
        val body = JSONObject()
            .put("topic", topic)
            .put("stack", stack)
            .put("level", level)
        entityId?.let { body.put("entity_id", it) }
        decode(api.post("work/interview/drill", body.toString()), interviewDrillAdapter)
    }

    private fun <T> decode(response: MobileApiClient.ApiResponse, adapter: com.squareup.moshi.JsonAdapter<T>): T {
        ensureOk(response)
        return adapter.fromJson(response.message)
            ?: throw MobileApiClient.ApiException.Http(response.status, "Decode failed")
    }

    private fun ensureOk(response: MobileApiClient.ApiResponse) {
        if (response.status == 401) throw MobileApiClient.ApiException.Unauthorized
        if (response.status !in 200..299) {
            throw MobileApiClient.ApiException.Http(response.status, response.message.take(280))
        }
    }

    private fun encode(value: String): String = java.net.URLEncoder.encode(value, Charsets.UTF_8.name())
}
