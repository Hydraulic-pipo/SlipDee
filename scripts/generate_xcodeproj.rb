require "xcodeproj"
require "fileutils"

project_path = File.expand_path("../SlipWise.xcodeproj", __dir__)
app_root = File.expand_path("../SlipWise", __dir__)

FileUtils.rm_rf(project_path) if File.exist?(project_path)

project = Xcodeproj::Project.new(project_path)
project.root_object.attributes["LastSwiftUpdateCheck"] = "1700"
project.root_object.attributes["LastUpgradeCheck"] = "1700"

target = project.new_target(:application, "SlipWise", :ios, "17.0")
target.product_name = "SlipWise"

target.build_configurations.each do |config|
    config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.example.SlipWise"
    config.build_settings["SWIFT_VERSION"] = "5.0"
    config.build_settings["INFOPLIST_KEY_UIApplicationSceneManifest_Generation"] = "YES"
    config.build_settings["INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents"] = "YES"
    config.build_settings["INFOPLIST_KEY_UILaunchScreen_Generation"] = "YES"
    config.build_settings["INFOPLIST_KEY_NSPhotoLibraryUsageDescription"] = "SlipWise lets you choose bank slip screenshots so it can read and organize transaction details."
    config.build_settings["INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone"] = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
    config.build_settings["INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad"] = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
    config.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
    config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "17.0"
    config.build_settings["TARGETED_DEVICE_FAMILY"] = "1,2"
    config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
    config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
    config.build_settings["DEVELOPMENT_TEAM"] = ""
    config.build_settings["SUPPORTS_MACCATALYST"] = "NO"
end

main_group = project.main_group
app_group = main_group.new_group("SlipWise", "SlipWise")
app_group.set_source_tree("<group>")

def add_folder(group, path, target)
    Dir.children(path).sort.each do |entry|
        full_path = File.join(path, entry)

        if File.directory?(full_path)
            child_group = group.new_group(entry, entry)
            add_folder(child_group, full_path, target)
        elsif File.extname(entry) == ".swift"
            file_ref = group.new_file(entry)
            target.add_file_references([file_ref])
        end
    end
end

add_folder(app_group, app_root, target)

resources_path = File.join(app_root, "Resources")
if Dir.exist?(resources_path)
    Dir.children(resources_path).sort.each do |entry|
        next unless entry.end_with?(".xcassets")
        file_ref = app_group.find_subpath("Resources", true).new_file(entry)
        target.resources_build_phase.add_file_reference(file_ref)
    end
end

project.save
