package com.personalos.mobile.ui.learning

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.personalos.mobile.data.models.PosEntity
import com.personalos.mobile.data.models.PosTodayStudyPlan
import com.personalos.mobile.data.repository.PersonalOSRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class LearningUiState(
    val loading: Boolean = true,
    val entities: List<PosEntity> = emptyList(),
    val today: PosTodayStudyPlan? = null,
    val error: String? = null,
)

class LearningViewModel(private val repository: PersonalOSRepository) : ViewModel() {
    private val _state = MutableStateFlow(LearningUiState())
    val state: StateFlow<LearningUiState> = _state.asStateFlow()

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            val entitiesResult = runCatching { repository.listEntities("learning") }
            val todayResult = runCatching { repository.fetchLearningToday() }
            val entities = entitiesResult.getOrNull()?.items ?: emptyList()
            val today = todayResult.getOrNull()
            val entityError = entitiesResult.exceptionOrNull()?.message
            val todayError = todayResult.exceptionOrNull()?.message
            when {
                entitiesResult.isFailure && todayResult.isFailure -> {
                    _state.value = LearningUiState(
                        loading = false,
                        error = entityError ?: todayError,
                    )
                }
                else -> {
                    _state.value = LearningUiState(
                        loading = false,
                        entities = entities,
                        today = today,
                        error = if (entitiesResult.isFailure) entityError else null,
                    )
                }
            }
        }
    }
}
