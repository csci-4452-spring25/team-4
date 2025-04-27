package org.weather.services;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.InputStreamResource;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Autowired;
import io.awspring.cloud.s3.S3Template;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.logging.Logger;

@Service
public class StorageService {
    @Value("${storage.bucket:default}")
    private String bucketName;

    @Value("${storage.base:weather-data}")
    private Resource basePath;

    @Autowired
    private S3Template s3Template;

    private final Logger logger = Logger.getLogger(StorageService.class.getName());

    public Resource getPath(String city) throws IOException {
        return basePath.createRelative(city + "/");
    }

    public String uploadCsv(File file, String key) {
        try (InputStream is = new FileInputStream(file)) {
            s3Template.upload(bucketName, key, is);
            return key;
        } catch (Exception e) {
            e.printStackTrace();
            logger.severe("Failed to upload CSV to S3: " + e.getMessage());
            throw new RuntimeException("Failed to upload CSV to S3", e);
        }
    }

    public InputStreamResource downloadCsv(String key) throws IOException {
        var s3Obj = s3Template.download(bucketName, key);
        return new InputStreamResource(s3Obj.getInputStream());
    }

    public boolean hasCsv(String key) {
        return s3Template.objectExists(bucketName, key);
    }
}
