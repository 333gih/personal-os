package com.personalos.mobile.ui.learning

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.personalos.mobile.data.models.PosEntity
import com.personalos.mobile.data.models.PosTodayStudyPlan
import com.personalos.mobile.data.repository.PersonalOSRepository
import kotlinx.coroutines.async
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
            runCatching {
                val entitiesDeferred = async { repository.listEntities("learning") }
                val todayDeferred = async { repository.fetchLearningToday() }
                entitiesDeferred.await() to todayDeferred.await()
            }.onSuccess { (list, today) ->
                _state.value = LearningUiState(loading = false, entities = list.items, today = today)
            }.onFailure {
                _state.value = LearningUiState(loading = false, error = it.message)
            }
        }
    }
}
