use anyhow::{anyhow, Result};
use std::path::{PathBuf, Path};

fn compile_fbs(path: impl AsRef<Path>) -> Result<()> {
    let out_dir = PathBuf::from(std::env::var("OUT_DIR")?);
    let path_ref = path.as_ref();
    let output_path = out_dir.join(
        path_ref
            .with_extension("rs")
            .file_name()
            .ok_or_else(|| anyhow!("path has no file_name: {:?}", path_ref))?,
    );
    let ugly = true;
    fbs_build::compile_fbs_generic(
        ugly,
        None,
        Box::new(std::fs::File::open(path_ref)?),
        Box::new(std::fs::File::create(output_path)?),
    )?;
    Ok(())
}

fn main() {
    compile_fbs("../pahkat-types/src/index.fbs").unwrap();
}
