package services

import (
	"log/slog"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/viper"
)

var (
	entrypointNames = []string{}

	dynamicConfigs TraefikDynamicConfigs
	staticConfigs  TraefikStaticConfigs
)

// Initialize service
func Initialize() {
	entrypoints := viper.GetStringMapString("vars.entryPoints")
	for k := range entrypoints {
		entrypointNames = append(entrypointNames, k)
	}
	slog.Info("show allow endpoint", "entrypoints", strings.Join(entrypointNames, ", "))

}

func UpdateStaticConfigs() {
	vars := viper.Sub("vars")
	// get static configs
	staticConfigs = NewTraefikStaticConfigs(vars)
	for _, k := range staticConfigs.v.AllKeys() {
		viper.Set("traefikStatic."+k, staticConfigs.v.Get(k))
	}
}

func UpdateDynamicConfigs() {
	vars := viper.Sub("vars")
	// get dynamic configs
	dynamicConfigs = NewTraefikDynamicConfigs(vars)
	for _, k := range dynamicConfigs.v.AllKeys() {
		viper.Set("traefikDynamic."+k, dynamicConfigs.v.Get(k))
	}
}

// ForceWriteConfigs Force write configs
func ForceWriteConfigs() {
	viper.WriteConfigAs("./.traefik-helper.yaml")
}

// ForceWriteDynamicConfig Force write dynamic configs
func ForceWriteDynamicConfig() {
	dynamicConfigsFile := dynamicConfigs.vars.GetString("dynamicConfigsFile")
	os.MkdirAll(filepath.Dir(dynamicConfigsFile), 0755)
	dynamicConfigs.v.WriteConfigAs(dynamicConfigsFile)
}

// ForceWriteStaticConfig Force write static configs
func ForceWriteStaticConfig() {
	staticConfigsFile := staticConfigs.vars.GetString("staticConfigsFile")
	os.MkdirAll(filepath.Dir(staticConfigsFile), 0755)
	staticConfigs.v.WriteConfigAs(staticConfigsFile)
}
