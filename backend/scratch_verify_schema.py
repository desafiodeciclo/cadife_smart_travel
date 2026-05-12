import sys
import os

# Add the app directory to sys.path
sys.path.append(os.path.abspath("app"))
sys.path.append(os.path.abspath("."))

from app.domain.entities.enums import PerfilViagem, OrcamentoPerfil
from app.models.briefing import BriefingExtracted

print(f"PerfilViagem.familia.value: {PerfilViagem.familia.value}")
print(f"OrcamentoPerfil.medio.value: {OrcamentoPerfil.medio.value}")

# Test normal creation
b1 = BriefingExtracted(perfil="familia", orcamento="medio")
print(f"Normal: perfil={b1.perfil}, orcamento={b1.orcamento}")

# Test accented creation (validator should handle it)
b2 = BriefingExtracted(perfil="família", orcamento="médio")
print(f"Accented: perfil={b2.perfil}, orcamento={b2.orcamento}")

if b2.perfil != PerfilViagem.familia or b2.orcamento != OrcamentoPerfil.medio:
    print("FAILURE: Validator did not normalize accented values!")
    sys.exit(1)

schema = BriefingExtracted.model_json_schema()
perfil_enum = schema["$defs"]["PerfilViagem"]["enum"]
orcamento_enum = schema["$defs"]["OrcamentoPerfil"]["enum"]

print(f"BriefingExtracted Perfil Enum: {perfil_enum}")
print(f"BriefingExtracted Orcamento Enum: {orcamento_enum}")

if "família" in perfil_enum or "médio" in orcamento_enum:
    print("FAILURE: Accents still present in schema!")
    sys.exit(1)
else:
    print("SUCCESS: No accents in schema and validators working.")
    sys.exit(0)
