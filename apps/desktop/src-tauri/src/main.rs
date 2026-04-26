#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::fs;
use std::path::Path;

#[tauri::command]
fn scan_music_folder(path: String) -> Result<Vec<String>, String> {
    fn walk(dir: &Path, out: &mut Vec<String>) -> Result<(), String> {
        for entry in fs::read_dir(dir).map_err(|e| e.to_string())? {
            let entry = entry.map_err(|e| e.to_string())?;
            let p = entry.path();
            if p.is_dir() {
                walk(&p, out)?;
            } else if let Some(ext) = p.extension() {
                let ext = ext.to_string_lossy().to_lowercase();
                if ["mp3", "flac", "wav", "ogg", "m4a", "aac"].contains(&ext.as_str()) {
                    out.push(p.to_string_lossy().to_string());
                }
            }
        }
        Ok(())
    }

    let mut files = Vec::new();
    walk(Path::new(&path), &mut files)?;
    Ok(files)
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![scan_music_folder])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
