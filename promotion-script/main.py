import os
from ruamel.yaml import YAML
from collections import defaultdict

version_string = "defaultVersion"
yaml = YAML()
ignored_folders = ['charts']

# TODO add the logic of adding selection of promoting depending on the tenant for example if its dev to move to test if its on cluster to move to all 
# Tenants etc just a logic of promotion with comand line so i can use it to a pipeline
# The this will create a pull request for the user to see the promotion will inclide delete the specific line of verion or maybe replace it with the TOP one?
def get_yaml_files(base_appspec_folder):
    yaml_files = []
    for root, dirs, files in os.walk(base_appspec_folder):
        dirs[:] = [d for d in dirs if d not in ignored_folders]
        for file in files:
            if file.endswith('.yaml') or file.endswith('.yml'):
                yaml_files.append(os.path.join(root, file))
    return yaml_files

def extract_versions(yaml_file):
    versions = {}
    try:
        with open(yaml_file, 'r') as file:
            for content in yaml.load_all(file):
                if isinstance(content, dict):
                    for key, value in content.items():
                        if isinstance(value, dict) and str(value).find(version_string) != -1:
                            versions[key] = {
                                'version': value[f'{version_string}'],
                                'path': yaml_file
                            }
    except Exception as e:
        print(f"Error processing {yaml_file}: {str(e)}")
    return versions

def get_versions(yaml_files):
    # Use defaultdict to automatically create empty dictionaries for new keys
    version_map = defaultdict(dict)
    
    for file in yaml_files:
        versions = extract_versions(file)
        for key, value in versions.items():
            version_map[key][file] = value['version']
    
    # Compare versions for each component
    for component, versions in version_map.items():
        if len(versions) > 1:
            print(f"\nComponent: {component}")
            print("Different versions found in:")
            for path, version in versions.items():
                print(f"  {path}: {version}")

def main():
    base_folder = "."
    yaml_files = get_yaml_files(base_folder)
    get_versions(yaml_files)

if __name__ == "__main__":
    main()
