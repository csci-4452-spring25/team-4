package org.weather.services;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Autowired;
import io.awspring.cloud.s3.S3Template;

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
}
