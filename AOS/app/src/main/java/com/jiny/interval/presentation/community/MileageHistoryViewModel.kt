package com.jiny.interval.presentation.community

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.jiny.interval.domain.model.MileageBalance
import com.jiny.interval.domain.model.MileageTransaction
import com.jiny.interval.domain.repository.MileageRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class MileageHistoryViewModel @Inject constructor(
    private val mileageRepository: MileageRepository
) : ViewModel() {

    val balance: StateFlow<MileageBalance> = mileageRepository.balance
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = MileageBalance.EMPTY
        )

    private val _transactions = MutableStateFlow<List<MileageTransaction>>(emptyList())
    val transactions: StateFlow<List<MileageTransaction>> = _transactions.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _isLoadingMore = MutableStateFlow(false)
    val isLoadingMore: StateFlow<Boolean> = _isLoadingMore.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private var currentPage = 1
    private var hasMoreData = true

    init {
        loadData()
    }

    fun loadData() {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            currentPage = 1
            hasMoreData = true

            mileageRepository.fetchBalance()

            mileageRepository.getHistory(page = 1)
                .onSuccess { transactions ->
                    _transactions.value = transactions
                    hasMoreData = transactions.size >= 20
                }
                .onFailure { e ->
                    _error.value = e.message
                }

            _isLoading.value = false
        }
    }

    fun loadMore() {
        if (_isLoadingMore.value || !hasMoreData) return

        viewModelScope.launch {
            _isLoadingMore.value = true

            val nextPage = currentPage + 1
            mileageRepository.getHistory(page = nextPage)
                .onSuccess { newTransactions ->
                    if (newTransactions.isEmpty()) {
                        hasMoreData = false
                    } else {
                        _transactions.value = _transactions.value + newTransactions
                        currentPage = nextPage
                        hasMoreData = newTransactions.size >= 20
                    }
                }
                .onFailure { e ->
                    _error.value = e.message
                }

            _isLoadingMore.value = false
        }
    }

    fun clearError() {
        _error.value = null
    }
}
