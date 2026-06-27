package com.personalos.mobile.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

object PosTheme {
    val Background = Color(0xFFF9F7F2)
    val Card = Color(0xFFFFFDFA)
    val Ink = Color(0xFF26201C)
    val Primary = Color(0xFFB03444)
    val PrimaryDark = Color(0xFF8C2634)
    val Muted = Color(0xFF766C62)
    val Border = Color(0xFFE4DCD2)
    val PaperLine = Color(0xFFDCD2C6)
    val PaperHighlight = Color.White
    val PaperShadow = Color(0xFF5A4637)
    val Focus = Color(0xFF3A6658)
    val Success = Color(0xFF2E784E)
    val SuccessBg = Color(0xFFE8F6EC)
    val Error = Color(0xFFB03444)
    val CardRadius = 20.dp
    val TabBarHeight = 60.dp
}

private val LightColors = lightColorScheme(
    primary = PosTheme.PrimaryDark,
    onPrimary = Color.White,
    background = PosTheme.Background,
    onBackground = PosTheme.Ink,
    surface = PosTheme.Card,
    onSurface = PosTheme.Ink,
    outline = PosTheme.Border,
)

@Composable
fun PersonalOSTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = LightColors,
        typography = androidx.compose.material3.Typography(
            headlineLarge = TextStyle(
                fontFamily = FontFamily.Serif,
                fontWeight = FontWeight.SemiBold,
                fontSize = 28.sp,
            ),
            titleMedium = TextStyle(
                fontFamily = FontFamily.Serif,
                fontWeight = FontWeight.SemiBold,
                fontSize = 17.sp,
            ),
            bodyMedium = TextStyle(fontSize = 14.sp),
            labelSmall = TextStyle(fontSize = 10.sp, fontWeight = FontWeight.SemiBold),
        ),
        content = content,
    )
}

fun posDisplay(size: Float = 28f, weight: FontWeight = FontWeight.SemiBold) = TextStyle(
    fontFamily = FontFamily.Serif,
    fontWeight = weight,
    fontSize = size.sp,
)

fun posLabel(size: Float = 11f) = TextStyle(
    fontWeight = FontWeight.Medium,
    fontSize = size.sp,
)

fun posCaps(size: Float = 10f) = TextStyle(
    fontWeight = FontWeight.SemiBold,
    fontSize = size.sp,
)
