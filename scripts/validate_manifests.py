import os
import json
import re
import sys


class DuplicateKeyError(ValueError):
    pass


def no_duplicate_object_pairs(pairs):
    obj = {}
    for key, value in pairs:
        if key in obj:
            raise DuplicateKeyError(key)
        obj[key] = value
    return obj


def load_json_no_duplicates(path, errors, root):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f, object_pairs_hook=no_duplicate_object_pairs)
    except DuplicateKeyError as exc:
        errors.append(f"{os.path.relpath(path, root)} has duplicate JSON key '{exc.args[0]}'")
        return {}


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    skills_dir = os.path.join(root, "skills")

    # 1. Get all modular skill folder names
    skill_folders = [d for d in os.listdir(skills_dir) if os.path.isdir(os.path.join(skills_dir, d))]
    print(f"Found {len(skill_folders)} modular skill folders: {', '.join(skill_folders)}")

    errors = []

    # Load package.json
    package_json_path = os.path.join(root, "package.json")
    package_data = load_json_no_duplicates(package_json_path, errors, root)
    package_skills = package_data.get("skills", {})

    # Load .claude-plugin/plugin.json
    plugin_json_path = os.path.join(root, ".claude-plugin", "plugin.json")
    plugin_data = load_json_no_duplicates(plugin_json_path, errors, root)
    plugin_skills = plugin_data.get("skills", [])
    plugin_skill_names = [item.get("name") for item in plugin_skills if item.get("name")]
    for name in sorted({name for name in plugin_skill_names if plugin_skill_names.count(name) > 1}):
        errors.append(f".claude-plugin/plugin.json declares duplicate skill name '{name}'")

    # Load README.md
    readme_path = os.path.join(root, "README.md")
    with open(readme_path, "r", encoding="utf-8") as f:
        readme_content = f.read()

    # Load templates/RULESET.md
    ruleset_path = os.path.join(root, "templates", "RULESET.md")
    with open(ruleset_path, "r", encoding="utf-8") as f:
        ruleset_content = f.read()

    # Check all modular skills
    for folder in skill_folders:
        skill_name = f"ak-{folder}"
        expected_path = f"skills/{folder}/SKILL.md"

        # A. check package.json
        if skill_name not in package_skills:
            errors.append(f"package.json is missing skill '{skill_name}'")
        elif package_skills[skill_name] != expected_path:
            errors.append(f"package.json has incorrect path for '{skill_name}': expected '{expected_path}', got '{package_skills[skill_name]}'")

        # B. check plugin.json
        plugin_match = next((s for s in plugin_skills if s.get("name") == skill_name), None)
        if not plugin_match:
            errors.append(f".claude-plugin/plugin.json is missing skill '{skill_name}'")
        elif plugin_match.get("path") != expected_path:
            errors.append(f".claude-plugin/plugin.json has incorrect path for '{skill_name}': expected '{expected_path}', got '{plugin_match.get('path')}'")

        # C. check SKILL.md frontmatter name
        skill_file_path = os.path.join(skills_dir, folder, "SKILL.md")
        if not os.path.isfile(skill_file_path):
            errors.append(f"Missing SKILL.md file at '{expected_path}'")
        else:
            with open(skill_file_path, "r", encoding="utf-8") as f:
                skill_content = f.read()
            # check name in frontmatter
            name_match = re.search(r"(?m)^name:\s*(\S+)", skill_content)
            if not name_match:
                errors.append(f"SKILL.md at '{expected_path}' is missing 'name' in frontmatter")
            elif name_match.group(1) != skill_name:
                errors.append(f"SKILL.md at '{expected_path}' has incorrect frontmatter name: expected '{skill_name}', got '{name_match.group(1)}'")

        # D. check README.md command table
        readme_search_str = f"skills/{folder}/SKILL.md"
        if readme_search_str not in readme_content:
            errors.append(f"README.md is missing reference to '{readme_search_str}' in command table")

        # E. check templates/RULESET.md command table
        ruleset_search_str = f".agents/skills/{folder}/SKILL.md"
        if ruleset_search_str not in ruleset_content:
            errors.append(f"templates/RULESET.md is missing reference to '{ruleset_search_str}' in command table")

    # Also verify that no extra skills are declared in package.json/plugin.json
    for key, path in package_skills.items():
        if key == "antariksh-unified-skill":
            if path != "SKILL.md":
                errors.append(f"package.json 'antariksh-unified-skill' has incorrect path: {path}")
            continue
        folder_name = key[3:] if key.startswith("ak-") else key
        if folder_name not in skill_folders:
            errors.append(f"package.json declares skill '{key}', but folder 'skills/{folder_name}' does not exist")

    for item in plugin_skills:
        name = item.get("name")
        path = item.get("path")
        if name == "antariksh-unified-skill":
            if path != "SKILL.md":
                errors.append(f".claude-plugin/plugin.json 'antariksh-unified-skill' has incorrect path: {path}")
            continue
        folder_name = name[3:] if name.startswith("ak-") else name
        if folder_name not in skill_folders:
            errors.append(f".claude-plugin/plugin.json declares skill '{name}', but folder 'skills/{folder_name}' does not exist")

    if errors:
        print("\nManifest parity checks FAILED with the following errors:")
        for err in errors:
            print(f" - {err}")
        sys.exit(1)
    else:
        print("\nManifest parity checks PASSED successfully! package.json, plugin.json, skill files, README, and RULESET are in sync.")
        sys.exit(0)

if __name__ == "__main__":
    main()
