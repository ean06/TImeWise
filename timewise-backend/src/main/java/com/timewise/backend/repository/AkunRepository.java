package com.timewise.backend.repository;

import com.timewise.backend.entity.Akun;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AkunRepository extends JpaRepository<Akun, Integer> {

    Akun findByUsernameAndPassword(String username, String password);

    Akun findByUsername(String username);
}