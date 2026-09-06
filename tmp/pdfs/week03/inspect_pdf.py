from pathlib import Path
import fitz

source = Path(r"C:\Users\Charmaine.Musheko\Downloads\week 03.pdf")
out_dir = Path(__file__).parent
doc = fitz.open(source)

parts = []
for index, page in enumerate(doc):
    parts.append(f"\n===== PAGE {index + 1} =====\n")
    parts.append(page.get_text("text"))
    pix = page.get_pixmap(matrix=fitz.Matrix(1.3, 1.3), alpha=False)
    pix.save(out_dir / f"page-{index + 1:02d}.png")

(out_dir / "week03.txt").write_text("".join(parts), encoding="utf-8")
print(f"pages={doc.page_count}")
print(f"metadata={doc.metadata}")
