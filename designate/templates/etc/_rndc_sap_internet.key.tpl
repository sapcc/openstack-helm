key "rndc-key" {
    algorithm hmac-md5;
    secret "{{ .Values.rndc_sap_internet_key }}";
};
