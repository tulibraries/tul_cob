import jQuery from "jquery"

const root = typeof window !== "undefined" ? window : global
const existing = root && (root.jQuery || root.$)
const jqueryInstance = existing || jQuery

if (root) {
  root.$ = jqueryInstance
  root.jQuery = jqueryInstance
}

export default jqueryInstance
