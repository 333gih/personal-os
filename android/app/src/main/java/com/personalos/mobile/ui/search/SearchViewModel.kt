package com.personalos.mobile.ui.search

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.personalos.mobile.data.models.PosSearchHit
import com.personalos.mobile.data.repository.PersonalOSRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class SearchUiState(
    val query: String = "",
    val mode: String = "hybrid",
    val loading: Boolean = false,
    val hits: List<PosSearchHit> = emptyList(),
    val recent: List<String> = emptyList(),
    val error: String? = null,
)

class SearchViewModel(
    private val repository: PersonalOSRepository,
    private val context: Context,
) : ViewModel() {
    private val _state = MutableStateFlow(SearchUiState(recent = loadRecent()))
    val state: StateFlow<SearchUiState> = _state.asStateFlow()

    fun setQuery(q: String) { _state.value = _state.value.copy(query = q) }
    fun setMode(mode: String) { _state.value = _state.value.copy(mode = mode) }

    fun search() {
        val q = _state.value.query.trim()
        if (q.isEmpty()) return
        viewModelScope.launch {
            _state.value = _state.value.copy(loading = true, error = null)
            runCatching { repository.search(q, _state.value.mode) }
                .onSuccess {
                    saveRecent(q)
                    _state.value = _state.value.copy(loading = false, hits = it.results, recent = loadRecent())
                }
                .onFailure { _state.value = _state.value.copy(loading = false, error = it.message) }
        }
    }

    private fun loadRecent(): List<String> =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getStringSet(KEY, emptySet())?.toList()?.take(8) ?: emptyList()

    private fun saveRecent(q: String) {
        val updated = (listOf(q) + loadRecent()).distinct().take(8)
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putStringSet(KEY, updated.toSet()).apply()
    }

    companion object {
        private const val PREFS = "com.personalos.search"
        private const val KEY = "recent"
    }
}
