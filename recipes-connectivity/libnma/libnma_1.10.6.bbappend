do_install:append () {
    rm -f ${D}${datadir}/glib-2.0/schemas/org.gnome.nm-applet.gschema.xml
}
