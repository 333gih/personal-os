package com.personalos.mobile.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.personalos.mobile.data.models.PosDashboard
import com.personalos.mobile.data.repository.PersonalOSRepository
import com.personalos.mobile.network.MobileApiClient
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class HomeUiState(
    val loading: Boolean = true,
    val dashboard: PosDashboard? = null,
    val error: String? = null,
)

class HomeViewModel(private val repository: PersonalOSRepository) : ViewModel() {
    private val _state = MutableStateFlow(HomeUiState())
    val state: StateFlow<HomeUiState> = _state.asStateFlow()

    fun load() {
        viewModelScope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            runCatching { repository.dashboard() }
                .onSuccess { _state.value = HomeUiState(loading = false, dashboard = it) }
                .onFailure { e ->
                    _state.value = HomeUiState(
                        loading = false,
                        error = when (e) {
                            MobileApiClient.ApiException.Unauthorized -> "Session expired"
                            is MobileApiClient.ApiException.Http -> e.message
                            else -> e.message ?: "Could not refresh"
                        },
                    )
                }
        }
    }
}
