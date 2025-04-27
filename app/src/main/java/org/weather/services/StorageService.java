package org.weather.services;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.InputStreamResource;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Autowired;
import io.awspring.cloud.s3.S3Template;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;

@Service
public class StorageService {
    @Value("${storage.bucket:default}")
    private String bucketName;

    @Value("${storage.base:root}")
    private Resource basePath;

    @Autowired
    private S3Template s3Template;

    public Resource getPath(String city) {
        try {
            return basePath.createRelative(city + "/");
        } catch (java.io.IOException e) {
            throw new RuntimeException("Failed to create relative resource for city: " + city, e);
        }
    }

    public String uploadCsv(File file, String key) {
        try (InputStream is = new FileInputStream(file)) {
            s3Template.upload(bucketName, key, is);
            return key;
        } catch (Exception e) {
            throw new RuntimeException("Failed to upload CSV to S3", e);
        }
    }

    public InputStreamResource downloadCsv(String key) {
        try {
            var s3Obj = s3Template.download(bucketName, key);
            return new InputStreamResource(s3Obj.getInputStream());
        } catch (Exception e) {
            throw new RuntimeException("Failed to download CSV from S3", e);
        }
    }

    public boolean hasCsv(String key) {
        try {
            return s3Template.objectExists(bucketName, key);
        } catch (Exception e) {
            throw new RuntimeException("Failed to check CSV existence in S3", e);
        }
    }
}
