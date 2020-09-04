declare module "mimemessage" {
  type ContentType = {
    type: string;
    subtype: string;
    fulltype: string;
    params: { [key: string]: string };
    value: string;
  };

  export class Entity {
    body: string | Entity[];
    contentType(): ContentType;
    contentType(v: string | null): void;
    contentTransferEncoding(): string | undefined;
    contentTransferEncoding(v: string | null): void;
    header(name: string): string | undefined;
    header(name: string, value: string | null): void;
    toString(options?: { noHeaders?: boolean }): string;
    isMultiPart(): boolean;
  }

  type FactoryParams = {
    contentType?: string;
    contentTransferEncoding?: string;
    body?: string | Entity[];
  };

  export function factory(f: FactoryParams): Entity;
  export function parse(d: string): Entity;
}
