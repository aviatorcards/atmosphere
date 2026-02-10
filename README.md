# Atmosphere

<p align="center">
  <img src="logo.png" alt="Atmosphere Logo" width="200"/>
</p>

Atmosphere is a simple and elegant journaling application for macOS. It provides a clean and distraction-free writing experience, allowing you to capture your thoughts, ideas, and memories with ease.

## Features

- **Markdown Support:** Write your entries in Markdown and see them beautifully rendered.
- **Journal Organization:** Organize your entries into different journals, each with its own name, icon, and color.
- **Rich Media:** Add photos, videos, and audio recordings to your entries.
- **Location Tracking:** Tag your entries with your current location.
- **Tagging:** Use tags to categorize and quickly find your entries.
- **Soft Deletes:** Deleted entries are moved to the trash, so you can restore them if needed.
- **Data Persistence:** Your data is stored locally on your machine in JSON format.

## Getting Started

To build and run Atmosphere, you will need Xcode 13 or later and macOS 12 or later.

1.  Clone the repository:
    ```bash
    git clone https://github.com/your-username/atmosphere.git
    ```
2.  Open the project in Xcode:
    ```bash
    xed .
    ```
3.  Build and run the project.

## Project Structure

The project is organized into the following directories:

- `Sources/atmosphere/`: Contains the main application logic.
  - `AtmosphereApp.swift`: The main entry point of the application.
  - `Models/`: Contains the data models for the application.
    - `Journal.swift`: Represents a journal.
    - `JournalEntry.swift`: Represents a single journal entry.
    - `JournalStore.swift`: Manages the persistence of journals and entries.
  - `Views/`: Contains the SwiftUI views for the application.
    - `SidebarView.swift`: The sidebar that displays the list of journals.
    - `EntryListView.swift`: The list of entries in a selected journal.
    - `EditorView.swift`: The editor for writing and editing journal entries.
  - `Resources/`: Contains the application's resources, such as images and other assets.

## Contributing

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request.
