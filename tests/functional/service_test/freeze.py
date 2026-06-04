"""
Minimal py2exe build script for a Windows service.

Usage (from this directory, with the project virtualenv active):
    python build_minimal_service.py

Output goes to:  py2exe_test\dist\
"""
import sys
import os
import glob

# Ensure this folder is on the path so py2exe can find minimal_service.py
sys.path.insert(0, os.path.dirname(__file__))

from py2exe import freeze

# Locate the pywin32 system DLLs (pywintypes3x.dll, pythoncom3x.dll).
# These are not picked up automatically by py2exe and must be shipped next
# to the compiled exe, otherwise win32service.pyd fails to load at runtime.
#
# Strategy: look in the pywin32_system32 sub-folder that sits alongside the
# win32 package, then fall back to the Scripts folder of the current venv.
import win32api as _win32api
_win32_pkg_dir = os.path.dirname(_win32api.__file__)          # …/site-packages/win32/
_pywin32_system32_dir = os.path.normpath(
    os.path.join(_win32_pkg_dir, "..", "pywin32_system32")
)
_pywin32_dlls = glob.glob(os.path.join(_pywin32_system32_dir, "*.dll"))

if not _pywin32_dlls:
    # Some venv layouts copy the DLLs into Scripts/
    _scripts_dir = os.path.join(sys.prefix, "Scripts")
    _pywin32_dlls = [
        p for p in glob.glob(os.path.join(_scripts_dir, "*.dll"))
        if os.path.basename(p).lower().startswith(("pywintypes", "pythoncom"))
    ]

if not _pywin32_dlls:
    raise RuntimeError(
        "Could not find pywintypes*.dll / pythoncom*.dll. "
        f"Searched: {_pywin32_system32_dir!r} and {_scripts_dir!r}. "
        "Check your pywin32 installation."
    )

data_files = [("", _pywin32_dlls)]

freeze(
    service=[
        {
            "modules": ["service_test"],
            "cmdline_style": "pywin32",
            "description": "Minimal test service",
        }
    ],
    options={
        "compressed": 2,
        "optimize": 2,
        "includes": ["pywintypes"],
        "excludes": [
            "_gtkagg", "_tkagg", "bsddb", "curses",
            "pywin.debugger", "pywin.debugger.dbgcon", "pywin.dialogs",
            "tcl", "tkinter", "doctest", "test",
        ],
        "packages": ["win32"],
        "dll_excludes": [
            "POWRPROF.dll",
            "API-MS-Win-Security-Base-L1-1-0.dll",
            "API-MS-Win-Core-ProcessThreads-L1-1-0.dll",
            "API-MS-Win-Core-LocalRegistry-L1-1-0.dll",
        ],
        "dist_dir": os.path.join(os.path.dirname(__file__), "dist"),
    },
    zipfile=None,
    data_files=data_files,
    version_info={
        "version": "1.0.0.0",
        "company_name": "Test",
        "copyright": "Test",
        "product_version": "1.0",
        "product_name": "Py2exeServiceTest",
    },
)
