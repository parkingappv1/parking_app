plugins {
    // Apply the Kotlin JVM plugin to add support for Kotlin.
    // id("org.jetbrains.kotlin.jvm") version "1.9.22" apply false
    // It's common to apply plugins in settings.gradle.kts or app/build.gradle.kts
    // For the root build.gradle.kts, the buildscript block is more traditional for AGP and Kotlin plugin
}

buildscript {
    val kotlinVersion = "1.9.22"
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirects the build output directory for the Android part of the Flutter project.
// Instead of `android/build`, outputs will go to `[flutter_project_root]/build/android_output_subfolder`.
// This helps keep all build artifacts in the main project's build directory.
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
