package com.timewise.backend.repository;

import com.timewise.backend.entity.Kategori;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface KategoriRepository extends JpaRepository<Kategori, Integer> {
    List<Kategori> findByAkunIdAkun(Integer idAkun);
}