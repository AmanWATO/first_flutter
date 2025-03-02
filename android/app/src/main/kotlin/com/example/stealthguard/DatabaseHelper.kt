package com.example.stealthguard

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.util.Log

class DatabaseHelper(context: Context) : SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val TAG = "DatabaseHelper"
        private const val DATABASE_VERSION = 1
        private const val DATABASE_NAME = "BrowsingHistory.db"

        // Table and column names
        const val TABLE_HISTORY = "history"
        const val COLUMN_ID = "_id"
        const val COLUMN_URL = "url"
        const val COLUMN_FAVICON = "favicon"
        const val COLUMN_TIMESTAMP = "timestamp"
    }

    override fun onCreate(db: SQLiteDatabase) {
        val createTableQuery = """
            CREATE TABLE $TABLE_HISTORY (
                $COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT, 
                $COLUMN_URL TEXT NOT NULL, 
                $COLUMN_FAVICON TEXT, 
                $COLUMN_TIMESTAMP TEXT NOT NULL
            );
        """.trimIndent()

        db.execSQL(createTableQuery)
        Log.d(TAG, "Database and tables created")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE_HISTORY")
        onCreate(db)
    }

    fun addHistoryEntry(url: String, favicon: String?, timestamp: String): Long {
        val db = writableDatabase
        val values = ContentValues().apply {
            put(COLUMN_URL, url)
            put(COLUMN_FAVICON, favicon ?: "") // Default empty if null
            put(COLUMN_TIMESTAMP, timestamp)
        }

        val id = db.insert(TABLE_HISTORY, null, values)
        Log.d(TAG, "History entry added with id: $id")
        return id
    }

    fun getAllHistory(): List<Map<String, String>> {
        val historyList = mutableListOf<Map<String, String>>()
        val selectQuery = "SELECT * FROM $TABLE_HISTORY ORDER BY $COLUMN_TIMESTAMP DESC"

        val db = readableDatabase
        db.rawQuery(selectQuery, null).use { cursor ->
            val urlIndex = cursor.getColumnIndexOrThrow(COLUMN_URL)
            val faviconIndex = cursor.getColumnIndexOrThrow(COLUMN_FAVICON)
            val timestampIndex = cursor.getColumnIndexOrThrow(COLUMN_TIMESTAMP)

            while (cursor.moveToNext()) {
                val historyItem = mapOf(
                    "url" to cursor.getString(urlIndex),
                    "favicon" to cursor.getString(faviconIndex),
                    "timestamp" to cursor.getString(timestampIndex)
                )
                historyList.add(historyItem)
            }
        }

        Log.d(TAG, "Retrieved ${historyList.size} history entries")
        return historyList
    }

    fun clearAllHistory() {
        val db = writableDatabase
        db.execSQL("DELETE FROM $TABLE_HISTORY")
        Log.d(TAG, "All history cleared")
    }
}
