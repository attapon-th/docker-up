package services

import (
	"log/slog"
	"os"
	"path/filepath"

	"github.com/samber/lo"
	"github.com/spf13/viper"
)

type TraefikStaticConfigs struct {
	vars *viper.Viper
	v    *viper.Viper
}

func NewTraefikStaticConfigs(vars *viper.Viper) TraefikStaticConfigs {

	c := TraefikStaticConfigs{
		vars: vars,
		v:    viper.Sub("traefikStatic"),
	}
	if c.vars == nil {
		slog.Error("vars not found")
		os.Exit(1)
	}
	if c.v == nil {
		slog.Error("traefikStatic not found")
		os.Exit(1)
	}

	// c.fixRouters()
	c.fix()
	return c
}
func (c *TraefikStaticConfigs) fix() {
	if c.v == nil {
		slog.Error("traefik-staric.entrypoints not found")
		os.Exit(1)
	}
	c.fixEntrypoints()
	c.fixCerts()
	c.fixAccesslog()

}

func (c *TraefikStaticConfigs) fixEntrypoints() {
	vars := c.vars
	v := c.v
	isUseWebAndWebsecure := lo.Contains(entrypointNames, "web") && lo.Contains(entrypointNames, "websecure")
	if vars.GetBool("tls") && isUseWebAndWebsecure {
		v.Set("web.http.redirections.entryPoint.to", "websecure")
		v.Set("web.http.redirections.entryPoint.scheme", "https")
		slog.Debug("set redirections http -> https", "to", "websecure", "scheme", "https")
	}
	for name, port := range vars.GetStringMapString("entryPoints") {
		slog.Debug("set "+name, "name", name, "address", ":"+port)
		v.Set(name, ":"+port)
	}
}
func (c *TraefikStaticConfigs) fixCerts() {
	vars := c.vars
	v := c.v

	if !vars.GetBool("tls") {
		return
	}

	if vars.GetString("certfile") == "" || vars.GetString("keyfile") == "" {
		v.Set("tls.stores.default", "{}")
	}
	certFile := vars.GetString("certfile")
	keyFile := vars.GetString("keyfile")
	certificates := []any{
		map[string]any{
			"certFile": "/certs/" + filepath.Base(certFile),
			"keyFile":  "/certs/" + filepath.Base(keyFile),
			"stores":   []string{"default"},
		},
	}
	v.Set("tls.certificates", certificates)
	slog.Debug("set certificates", "certFile", certFile, "keyFile", keyFile)

}

func (c *TraefikStaticConfigs) fixAccesslog() {
	vars := c.vars
	v := c.v
	if !vars.IsSet("accessLogFilePath") {
		return
	}
	v.Set("accesslog.filepath", vars.GetString("accessLogFilePath"))
	slog.Debug("set accessLogFilePath", "filepath", vars.GetString("accessLogFilePath"))
}
