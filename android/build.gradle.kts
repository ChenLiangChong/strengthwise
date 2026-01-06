buildscript {
    repositories {
        // Google 優先（Firebase plugins 只在 Google 倉庫有）
        google()
        // 阿里雲鏡像替代 Maven Central（避免 403）
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
        // Firebase Cloud Messaging（推播通知）⭐ v3.0-C
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 為所有子專案（包括 Flutter plugins）覆蓋 buildscript repositories
// 解決 GitHub Actions 無法從 Maven Central 下載依賴的 403 問題
subprojects {
    buildscript {
        repositories {
            google()
            maven { url = uri("https://maven.aliyun.com/repository/public") }
            maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
            mavenCentral()
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
