package com.personalos.mobile.ui.entity

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.personalos.mobile.data.models.PosEntity
import com.personalos.mobile.data.models.PosEntityDetailResponse
import com.personalos.mobile.data.models.PosRelationItem
import com.personalos.mobile.data.repository.PersonalOSRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class EntityDetailUiState(
    val loading: Boolean = true,
    val entity: PosEntity? = null,
    val relations: List<PosRelationItem> = emptyList(),
    val error: String? = null,
)

class EntityDetailViewModel(
    private val repository: PersonalOSRepository,
    private val entityId: String,
) : ViewModel() {
    private val _state = MutableStateFlow(EntityDetailUiState())
    val state: StateFlow<EntityDetailUiState> = _state.asStateFlow()

    init { load() }

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            runCatching { repository.entityDetail(entityId) }
                .onSuccess { apply(it) }
                .onFailure { _state.value = EntityDetailUiState(loading = false, error = it.message) }
        }
    }

    private fun apply(resp: PosEntityDetailResponse) {
        _state.value = EntityDetailUiState(
            loading = false,
            entity = resp.entity,
            relations = resp.relations,
        )
    }
}
