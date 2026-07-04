package com.personalos.mobile.ui.modules

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.personalos.mobile.data.models.PosModuleCatalogEntry
import com.personalos.mobile.data.models.PosModulePref
import com.personalos.mobile.data.models.PosModuleUpdatePref
import com.personalos.mobile.data.models.PosModulesResponse
import com.personalos.mobile.data.repository.PersonalOSRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ModulesViewModel(
    private val repository: PersonalOSRepository,
) : ViewModel() {
    private val _state = MutableStateFlow(PosModulesResponse())
    val state: StateFlow<PosModulesResponse> = _state.asStateFlow()

    private val _loading = MutableStateFlow(false)
    val loading: StateFlow<Boolean> = _loading.asStateFlow()

    val bottomTabIds: List<String>
        get() {
            val tabs = _state.value.nav.tabs.toMutableList()
            if (_state.value.nav.drawer.isNotEmpty() && !tabs.contains("more")) {
                tabs.add("more")
            }
            return tabs
        }

    fun refresh(force: Boolean = false) {
        if (!force && _state.value.catalog.isNotEmpty()) return
        viewModelScope.launch {
            _loading.value = true
            runCatching { repository.fetchModules() }
                .onSuccess { _state.value = it }
            _loading.value = false
        }
    }

    fun isEnabled(moduleId: String): Boolean =
        _state.value.prefs.find { it.moduleId == moduleId }?.enabled ?: true

    fun domainModules(): List<PosModuleCatalogEntry> =
        _state.value.catalog.filter { it.tier == "domain" }

    fun updateModules(updates: List<Pair<String, Boolean?>>) {
        viewModelScope.launch {
            _loading.value = true
            runCatching {
                repository.updateModules(
                    updates.map { PosModuleUpdatePref(moduleId = it.first, enabled = it.second) },
                )
            }.onSuccess { _state.value = it }
            _loading.value = false
        }
    }
}
