import ciSchemaPath from '~/editor/schema/ci.json';
import { registerSchema } from '~/ide/utils';
import { SourceEditorExtension } from './source_editor_extension_base';

export class CiSchemaExtension extends SourceEditorExtension {
  /**
   * Registers a syntax schema to the editor based on project
   * identifier and commit.
   *
   * The schema is added to the file that is currently edited
   * in the editor.
   *
   * @param {Object} opts
   * @param {String} opts.projectNamespace
   * @param {String} opts.projectPath
   * @param {String?} opts.ref - Current ref. Defaults to main
   */
  registerCiSchema() {
    // In order for workers loaded from `data://` as the
    // ones loaded by monaco editor, we use absolute URLs
    // to fetch schema files, hence the `gon.gitlab_url`
    // reference. This prevents error:
    //   "Failed to execute 'fetch' on 'WorkerGlobalScope'"
    const absoluteSchemaUrl = gon.gitlab_url + ciSchemaPath;
    const modelFileName = this.getModel().uri.path.split('/').pop();

    registerSchema({
      uri: absoluteSchemaUrl,
      fileMatch: [modelFileName],
    });
  }
}
