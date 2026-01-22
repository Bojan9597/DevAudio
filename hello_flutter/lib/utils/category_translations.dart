import '../l10n/generated/app_localizations.dart';

String translateCategoryTitle(String title, AppLocalizations l10n) {
  // Map English titles to their localization keys
  final Map<String, String Function(AppLocalizations)> titleToKey = {
    'Programming': (l) => l.catProgramming,
    'Operating Systems': (l) => l.catOperatingSystems,
    'Linux': (l) => l.catLinux,
    'Networking': (l) => l.catNetworking,
    'File Systems': (l) => l.catFileSystems,
    'Security': (l) => l.catSecurity,
    'Shell Scripting': (l) => l.catShellScripting,
    'System Administration': (l) => l.catSystemAdministration,
    'Windows': (l) => l.catWindows,
    'Internals': (l) => l.catInternals,
    'PowerShell': (l) => l.catPowerShell,
    'macOS': (l) => l.catMacOS,
    'Shell & Scripting': (l) => l.catShellAndScripting,
    'Programming Languages': (l) => l.catProgrammingLanguages,
    'Python': (l) => l.catPython,
    'Basics': (l) => l.catBasics,
    'Advanced Topics': (l) => l.catAdvancedTopics,
    'Web Development': (l) => l.catWebDevelopment,
    'Data Science': (l) => l.catDataScience,
    'Scripting & Automation': (l) => l.catScriptingAndAutomation,
    'C / C++': (l) => l.catCCpp,
    'C Basics': (l) => l.catCBasics,
    'C++ Basics': (l) => l.catCppBasics,
    'C++ Advanced': (l) => l.catCppAdvanced,
    'STL': (l) => l.catSTL,
    'System Programming': (l) => l.catSystemProgramming,
    'Java': (l) => l.catJava,
    'Object-Oriented Programming': (l) => l.catOOP,
    'Concurrency & Threads': (l) => l.catConcurrencyAndThreads,
    'JavaScript': (l) => l.catJavaScript,
    'Browser & DOM': (l) => l.catBrowserAndDOM,
    'Node.js': (l) => l.catNodeJs,
    'Frameworks (React, Vue, Angular)': (l) => l.catFrameworks,
  };

  // If we have a translation, return it. Otherwise, return the original title.
  final translator = titleToKey[title];
  return translator != null ? translator(l10n) : title;
}
