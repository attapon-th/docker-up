package services

import (
	"log/slog"
	"os"
	"strings"

	"github.com/samber/lo"
	"github.com/spf13/viper"
)

type TraefikDynamicConfigs struct {
	vars *viper.Viper
	v    *viper.Viper
}

func NewTraefikDynamicConfigs(vars *viper.Viper) TraefikDynamicConfigs {

	c := TraefikDynamicConfigs{
		vars: vars,
		v:    viper.Sub("traefikDynamic"),
	}
	if c.vars == nil {
		slog.Error("vars not found")
		os.Exit(1)
	}
	if c.v == nil {
		slog.Error("traefikDynamic not found")
		os.Exit(1)
	}

	c.fixRouters()
	return c
}

func (c *TraefikDynamicConfigs) fixRouters() {
	router := c.v.Sub("http.routers")
	vars := c.vars
	for _, k := range router.AllKeys() {
		k = strings.ToLower(k)

		// set TLS
		if strings.HasSuffix(k, ".tls") {
			router.Set(k, vars.GetBool("tls"))
			slog.Debug("set tls", "tls", vars.GetBool("tls"))
		}

		// set Router Rule
		// ex: Host(`{{DOMAIN}}`) && Path(`/ping`)
		if strings.HasSuffix(k, ".rule") {
			s := router.GetString(k)
			s = strings.ReplaceAll(s, "{{DOMAIN}}", vars.GetString("domain"))
			router.Set(k, s)
			slog.Debug("set rule", "domain", vars.GetString("domain"), "rule", k)
		}

		// set entryPoints if allow
		if strings.HasSuffix(k, ".entrypoints") {
			s := router.GetStringSlice(k)
			eps := []string{}
			for _, v := range s {
				if lo.Contains(entrypointNames, v) {
					eps = append(eps, v)
				}
			}
			router.Set(k, eps)
			slog.Debug("set entryPoints", "name", strings.TrimSuffix(k, ".entrypoints"), "entryPoints", eps)
		}
	}
}
