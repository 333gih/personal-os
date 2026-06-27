package com.personalos.mobile.ui.work

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.personalos.mobile.data.models.PosEntity
import com.personalos.mobile.data.repository.PersonalOSRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class WorkUiState(
    val loading: Boolean = true,
    val entities: List<PosEntity> = emptyList(),
    val error: String? = null,
)

class WorkViewModel(private val repository: PersonalOSRepository) : ViewModel() {
    private val _state = MutableStateFlow(WorkUiState())
    val state: StateFlow<WorkUiState> = _state.asStateFlow()

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            runCatching { repository.listEntities("work") }
                .onSuccess { _state.value = WorkUiState(loading = false, entities = it.items) }
                .onFailure { _state.value = WorkUiState(loading = false, error = it.message) }
        }
    }
}
