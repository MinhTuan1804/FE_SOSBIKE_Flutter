import os

def search_usages():
    search_dir = r"e:\Ki 8\EXE201_Project\fe_moblie_flutter\lib"
    target = "MechanicOrderMapBackground"
    for root, dirs, files in os.walk(search_dir):
        for file in files:
            if file.endswith(".dart"):
                path = os.path.join(root, file)
                with open(path, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                    if target in content:
                        print(f"Found usage in: {path}")

if __name__ == "__main__":
    search_usages()
