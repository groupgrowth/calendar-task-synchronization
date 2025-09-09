
# Calendar Task Synchronization [![Deploy (SSH + Docker Compose)](https://github.com/groupgrowth/calendar-task-synchronization/actions/workflows/deploy-docker.yml/badge.svg)](https://github.com/groupgrowth/calendar-task-synchronization/actions/workflows/deploy-docker.yml)


This application synchronizes **OpenProject work packages** with **Google Calendar events** and logs synchronization actions/errors into **Google Sheets**. It also provides a **Streamlit interface** for managing configurations and triggering synchronizations manually.

---

## Features

* 🔄 **Bidirectional reconciliation** between OpenProject tasks and Google Calendar events (create, update, delete).
* 🗓️ Automatic mapping of Work Packages to Calendar events:

  * Event title includes WP ID and subject.
  * Event description contains department, parent, assignee, updated timestamp, due hour, and deep link to WP.
* 📊 Logging of synchronization results (actions and errors) in Google Sheets.
* 🖥️ **Streamlit web UI** for:

  * Managing multiple sync profiles (.ini + credentials).
  * Running synchronizations on demand.
  * Checking cron/Task Scheduler status.
* ⚙️ Automation support:

  * Windows: Task Scheduler with provided `.xml` and `run_main.vbs`.
  * Linux: `cron` with provided `synchronization.sh` script.

---

## Project Structure

```
app.md                  # Documentation
app.py                  # Streamlit multi-tab app
config_interface.py     # Streamlit component for config management
main.py                 # Orchestrator of a sync run
synchronization.py      # Sync engine (OpenProject ↔ Google Calendar ↔ Google Sheets)
config_files/           # Stores sync profiles and credentials
  ├── *.ini             # Per-sync configuration files
  └── keys/             # Google Service Account JSON keys
```

---

## Configuration

Each synchronization is defined by an **INI file** inside `config_files/`. Example:

```ini
[security]
NAME = Team Marketing
CALENDAR_ID_EMAIL = your-calendar-id@group.calendar.google.com
PROJECTS_API_KEY = <your-openproject-api-key>
SHEET_ID = <google-sheets-id>
CREDENTIALS_PATH = config_files/keys/google_keys.json

# Define one origin filter
type = assignee
ASSIGNEE_ID = 123
# or
type = project
PROJECT_NAME = Project A, Project B
```

* `CALENDAR_ID_EMAIL`: Target Google Calendar ID.
* `PROJECTS_API_KEY`: OpenProject API key.
* `SHEET_ID`: Google Sheet for logs.
* `CREDENTIALS_PATH`: Path to Google Service Account JSON key.
* **Origin filter**: Either `ASSIGNEE_ID` (single user) or `PROJECT_NAME` (comma-separated list).

---

## Running the Application

### 1. Streamlit Interface

```bash
streamlit run app.py
```

* Manage sync profiles.
* Trigger manual synchronizations.
* Inspect automation status.

### 2. Manual Run

```bash
python main.py config_files/your_sync.ini
```

### 3. Automation

* **Windows**:

  * Import `task_scheduler.xml` into Task Scheduler.
  * Uses `run_main.vbs` to execute syncs.
* **Linux**:

  * Add entry to `cron` using `synchronization.sh`.
  * Example:

    ```cron
    0 * * * * /path/to/synchronization.sh /path/to/config_files/team_marketing.ini
    ```

---

## Google Integration

The application uses a **Google Service Account** with the following scopes:

* `https://www.googleapis.com/auth/calendar`
* `https://www.googleapis.com/auth/spreadsheets`

Grant the Service Account access to:

* The target Google Calendar (share with service account email).
* The Google Sheet (editor access).

---

## Logging

All sync runs append logs into the configured Google Sheet:

* **Sheet `actions`**: IDs of created, deleted, updated events per run.
* **Sheet `errors`**: Any error messages during execution.

---

## Development Notes

* **Event matching** is based on WP ID embedded in the event summary.
* **Updates** are triggered when `updatedAt` differs between OpenProject and the stored event.
* **Ignored WPs**: Work Packages with `description` empty or starting with `!!!`.
* **Event times**: Default 08:00–18:00 if not specified; `DueHour` overrides end time.

---

## Requirements

* Python 3.10+
* Dependencies: `streamlit`, `google-api-python-client`, `google-auth`, `requests`

Install via:

```bash
pip install -r requirements.txt
```

---

## License

MIT License.
