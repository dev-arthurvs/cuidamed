package com.cuidamed.cuidamed_backend.farmacias;

import java.util.List;

public record RespostaFarmaciasDTO(PontoOrigemDTO origem, List<FarmaciaDTO> farmacias) {
}
