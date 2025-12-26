# Third-Party Frameworks

This directory should contain the `llama.xcframework` file.

## Required Framework

- **llama.xcframework**: Prebuilt llama.cpp framework for iOS

The framework should be placed directly in this directory:
```
ThirdParty/Frameworks/llama.xcframework/
```

## Build Configuration

The project is configured to search for frameworks in this location via:
- `FRAMEWORK_SEARCH_PATHS = "$(PROJECT_DIR)/ThothAI/ThirdParty/Frameworks"`

## Note

If this framework is missing, the build will fail with:
```
'llama/llama.h' file not found
```

Please restore the `llama.xcframework` to this location to build successfully.

