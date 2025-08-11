import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.gradle.api.file.Directory

plugins {
    id("com.google.gms.google-services") version "4.4.3" apply false
    // If this is the root project, add the Kotlin plugin if needed globally:
    // id("org.jetbrains.kotlin.jvm") version "1.9.10" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Custom build directory (optional but okay)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Kotlin compilation settings — only works if Kotlin plugin is applied in subprojects
tasks.withType<KotlinCompile>().configureEach {
    kotlinOptions {
        incremental = false
    }
}
