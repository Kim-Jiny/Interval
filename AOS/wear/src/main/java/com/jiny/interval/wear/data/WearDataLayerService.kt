package com.jiny.interval.wear.data

import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

class WearDataLayerService : WearableListenerService() {

    companion object {
        private const val ROUTINES_PATH = "/routines"
        private const val TIMER_CONTROL_PATH = "/timer/control"
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        super.onDataChanged(dataEvents)

        dataEvents.forEach { event ->
            val uri = event.dataItem.uri
            when (uri.path) {
                ROUTINES_PATH -> {
                    // Handle routine sync from phone
                    // TODO: Parse routine data and store locally
                }
            }
        }
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        super.onMessageReceived(messageEvent)

        when (messageEvent.path) {
            TIMER_CONTROL_PATH -> {
                // Handle timer control messages
                val message = String(messageEvent.data)
                // TODO: Process control commands (start, stop, etc.)
            }
        }
    }
}
