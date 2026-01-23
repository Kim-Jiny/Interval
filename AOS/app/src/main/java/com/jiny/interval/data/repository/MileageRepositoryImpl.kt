package com.jiny.interval.data.repository

import com.jiny.interval.data.mapper.toDomain
import com.jiny.interval.data.remote.api.MileageApi
import com.jiny.interval.domain.model.MileageBalance
import com.jiny.interval.domain.model.MileageTransaction
import com.jiny.interval.domain.repository.MileageRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class MileageRepositoryImpl @Inject constructor(
    private val mileageApi: MileageApi
) : MileageRepository {

    private val _balance = MutableStateFlow(MileageBalance.EMPTY)
    override val balance: Flow<MileageBalance> = _balance.asStateFlow()

    override suspend fun fetchBalance(): Result<MileageBalance> {
        return try {
            val response = mileageApi.getBalance()
            if (response.isSuccessful && response.body()?.success == true) {
                val body = response.body()!!
                val balanceDto = body.mileage ?: body.data
                val balance = balanceDto?.toDomain() ?: MileageBalance.EMPTY
                _balance.value = balance
                Result.success(balance)
            } else {
                Result.failure(Exception("Failed to get balance"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getHistory(page: Int, limit: Int): Result<List<MileageTransaction>> {
        return try {
            val response = mileageApi.getHistory(page, limit)
            if (response.isSuccessful && response.body()?.success == true) {
                val body = response.body()!!
                val transactionDtos = body.transactions ?: body.data ?: emptyList()
                val transactions = transactionDtos.map { it.toDomain() }
                Result.success(transactions)
            } else {
                Result.failure(Exception("Failed to get history"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
