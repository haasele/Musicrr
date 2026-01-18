package com.haasele.musicrr.visualizer

import android.util.Log
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserFactory
import java.io.File
import java.io.FileInputStream

/**
 * Parser for .milk preset files (Winamp MilkDrop format)
 * This is a simplified parser that extracts key variables and equations
 */
data class MilkPreset(
    val name: String,
    val variables: Map<String, Float>,
    val equations: List<String>,
    val shaderCode: String? = null
)

class MilkPresetParser {
    companion object {
        private const val TAG = "MilkPresetParser"
    }
    
    /**
     * Parse a .milk preset file
     */
    fun parsePreset(file: File): MilkPreset? {
        if (!file.exists() || !file.name.endsWith(".milk", ignoreCase = true)) {
            return null
        }
        
        return try {
            val factory = XmlPullParserFactory.newInstance()
            factory.isNamespaceAware = false
            val parser = factory.newPullParser()
            
            FileInputStream(file).use { input ->
                parser.setInput(input, "UTF-8")
                parsePresetContent(parser, file.nameWithoutExtension)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing preset file: ${file.name}", e)
            null
        }
    }
    
    private fun parsePresetContent(parser: XmlPullParser, defaultName: String): MilkPreset {
        var name = defaultName
        val variables = mutableMapOf<String, Float>()
        val equations = mutableListOf<String>()
        var shaderCode: String? = null
        
        var eventType = parser.eventType
        while (eventType != XmlPullParser.END_DOCUMENT) {
            when (eventType) {
                XmlPullParser.START_TAG -> {
                    when (parser.name) {
                        "preset" -> {
                            name = parser.getAttributeValue(null, "name") ?: defaultName
                        }
                        "variable" -> {
                            val varName = parser.getAttributeValue(null, "name") ?: continue
                            val value = parser.getAttributeValue(null, "value")?.toFloatOrNull()
                            if (value != null) {
                                variables[varName] = value
                            }
                        }
                        "equation" -> {
                            val eq = parser.nextText().trim()
                            if (eq.isNotEmpty()) {
                                equations.add(eq)
                            }
                        }
                        "shader" -> {
                            shaderCode = parser.nextText().trim()
                        }
                    }
                }
            }
            eventType = parser.next()
        }
        
        return MilkPreset(
            name = name,
            variables = variables,
            equations = equations,
            shaderCode = shaderCode
        )
    }
    
    /**
     * Parse preset from string content
     */
    fun parsePresetFromString(content: String, name: String = "Custom"): MilkPreset? {
        return try {
            val factory = XmlPullParserFactory.newInstance()
            factory.isNamespaceAware = false
            val parser = factory.newPullParser()
            parser.setInput(content.byteInputStream(), "UTF-8")
            parsePresetContent(parser, name)
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing preset from string", e)
            null
        }
    }
}
