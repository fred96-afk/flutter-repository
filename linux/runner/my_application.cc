#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void ensure_desktop_integration(const gchar* icon_path) {
  if (icon_path == nullptr || !g_file_test(icon_path, G_FILE_TEST_EXISTS)) {
    return;
  }

  const gchar* user_data_dir = g_get_user_data_dir();
  if (user_data_dir == nullptr) {
    return;
  }

  // 1. Ensure icon exists in ~/.local/share/icons/hicolor/256x256/apps/
  g_autofree gchar* icon_dir = g_build_filename(user_data_dir, "icons", "hicolor", "256x256", "apps", nullptr);
  g_mkdir_with_parents(icon_dir, 0755);
  g_autofree gchar* target_icon = g_build_filename(icon_dir, APPLICATION_ID ".png", nullptr);
  if (!g_file_test(target_icon, G_FILE_TEST_EXISTS)) {
    g_autoptr(GFile) src = g_file_new_for_path(icon_path);
    g_autoptr(GFile) dst = g_file_new_for_path(target_icon);
    g_file_copy(src, dst, G_FILE_COPY_OVERWRITE, nullptr, nullptr, nullptr, nullptr);
  }

  // 2. Ensure .desktop file exists in ~/.local/share/applications/
  g_autofree gchar* app_dir = g_build_filename(user_data_dir, "applications", nullptr);
  g_mkdir_with_parents(app_dir, 0755);
  g_autofree gchar* desktop_path = g_build_filename(app_dir, APPLICATION_ID ".desktop", nullptr);
  if (!g_file_test(desktop_path, G_FILE_TEST_EXISTS)) {
    g_autofree gchar* exe_path = g_file_read_link("/proc/self/exe", nullptr);
    if (exe_path != nullptr) {
      g_autofree gchar* desktop_content = g_strdup_printf(
          "[Desktop Entry]\n"
          "Version=1.0\n"
          "Type=Application\n"
          "Name=Pollería El Gigante\n"
          "Comment=Sistema Móvil de Pedidos - Pollería El Gigante\n"
          "Exec=%s\n"
          "Icon=%s\n"
          "Terminal=false\n"
          "Categories=Utility;Office;\n"
          "StartupWMClass=%s\n",
          exe_path, target_icon, APPLICATION_ID);
      g_file_set_contents(desktop_path, desktop_content, -1, nullptr);
    }
  }
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "polleria_movil");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "polleria_movil");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  const gchar* assets_path = fl_dart_project_get_assets_path(project);
  g_autofree gchar* icon_path =
      g_build_filename(assets_path, "assets", "images", "app_icon.png", nullptr);

  ensure_desktop_integration(icon_path);

  gtk_window_set_default_icon_name(APPLICATION_ID);
  gtk_window_set_icon_name(window, APPLICATION_ID);
  if (g_file_test(icon_path, G_FILE_TEST_EXISTS)) {
    gtk_window_set_icon_from_file(window, icon_path, nullptr);
  }

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
